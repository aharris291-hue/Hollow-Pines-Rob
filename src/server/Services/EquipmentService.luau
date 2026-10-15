-- Builds each player's loadout as Roblox Tools and runs them: flashlight and
-- lantern batteries, walkie pings, the camera flash and the calming flask.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Items = require(Shared.Config.Items)
local Assets = require(Shared.Config.Assets)
local Net = require(Shared.Util.Net)
local RateLimit = require(Shared.Util.RateLimit)
local GameConfig = require(Shared.Config.GameConfig)
local EventBus = require(script.Parent.Parent.EventBus)

local EquipmentService = {}

local TICK = 0.5

local services
local enabled = false -- tools are handed out once the emergency kit is found
local cooldowns: { [Player]: { [string]: number } } = {}
local toggleLimiter = RateLimit.new(0.2)
local tonicUsed: { [Player]: boolean } = {}
local storyItems: { [Player]: { [string]: boolean } } = {} -- re-given after a respawn

local function lightOf(tool: Tool): Light?
	local handle = tool:FindFirstChild("Handle")
	return handle and handle:FindFirstChildWhichIsA("Light") :: Light?
end

local function heldTool(player: Player): Tool?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Tool")
end

local function findTool(player: Player, itemId: string): Tool?
	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")
	for _, container in { character, backpack } do
		if container then
			for _, child in container:GetChildren() do
				if child:IsA("Tool") and child:GetAttribute("ItemId") == itemId then
					return child
				end
			end
		end
	end
	return nil
end

local function onCooldown(player: Player, itemId: string, seconds: number): boolean
	cooldowns[player] = cooldowns[player] or {}
	local now = os.clock()
	local readyAt = cooldowns[player][itemId] or 0
	if now < readyAt then
		return true
	end
	cooldowns[player][itemId] = now + seconds
	return false
end

local function makeHandle(size: Vector3, color: Color3): Part
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = size
	handle.Color = color
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Massless = true
	return handle
end

local function setLight(tool: Tool, on: boolean)
	local light = lightOf(tool)
	if not light then
		return
	end
	local hasBattery = (tool:GetAttribute("Battery") or 0) > 0
	light.Enabled = on and hasBattery
	tool:SetAttribute("On", light.Enabled)
end

local function buildTool(player: Player, itemId: string): Tool?
	local item = Items.Equipment[itemId]
	if not item then
		return nil
	end
	local tool = Instance.new("Tool")
	tool.Name = item.name
	tool.ToolTip = item.description
	tool.CanBeDropped = false
	tool:SetAttribute("ItemId", itemId)

	if itemId == "Flashlight" then
		local handle = makeHandle(Vector3.new(0.45, 0.45, 1.8), Color3.fromRGB(40, 40, 44))
		local light = Instance.new("SpotLight")
		light.Face = Enum.NormalId.Front
		light.Range = item.range
		light.Brightness = item.brightness
		light.Angle = 55
		light.Shadows = true
		light.Enabled = false
		light.Parent = handle
		handle.Parent = tool
		tool:SetAttribute("Battery", item.battery)
		tool:SetAttribute("MaxBattery", item.battery)
	elseif itemId == "Lantern" then
		local handle = makeHandle(Vector3.new(1, 1.4, 1), Color3.fromRGB(150, 110, 60))
		local light = Instance.new("PointLight")
		light.Range = item.range
		light.Brightness = item.brightness
		light.Color = Color3.fromRGB(255, 200, 120)
		light.Shadows = true
		light.Enabled = false
		light.Parent = handle
		handle.Parent = tool
		tool:SetAttribute("Battery", item.battery)
		tool:SetAttribute("MaxBattery", item.battery)
	elseif itemId == "Walkie" then
		makeHandle(Vector3.new(0.5, 1.2, 0.3), Color3.fromRGB(30, 30, 30)).Parent = tool
	elseif itemId == "Whistle" then
		makeHandle(Vector3.new(0.3, 0.3, 0.9), Color3.fromRGB(200, 170, 60)).Parent = tool
	elseif itemId == "Camera" then
		makeHandle(Vector3.new(1, 0.7, 0.6), Color3.fromRGB(220, 220, 210)).Parent = tool
	elseif itemId == "CalmTonic" then
		if tonicUsed[player] then
			return nil
		end
		makeHandle(Vector3.new(0.5, 1, 0.5), Color3.fromRGB(120, 160, 120)).Parent = tool
	end

	tool.Activated:Connect(function()
		EquipmentService:_activate(player, tool, itemId)
	end)
	tool.Unequipped:Connect(function()
		setLight(tool, false)
	end)
	return tool
end

function EquipmentService:_activate(player: Player, tool: Tool, itemId: string)
	local item = Items.Equipment[itemId]
	if itemId == "Flashlight" or itemId == "Lantern" then
		if toggleLimiter:Allow(player) then
			setLight(tool, not tool:GetAttribute("On"))
		end
	elseif itemId == "Walkie" then
		if onCooldown(player, itemId, item.cooldown) then
			return
		end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			Net.Event("WalkiePing"):FireAllClients(player, root.Position)
			EventBus.Fire("WalkiePing", player)
			if services.NoiseService then
				services.NoiseService:Emit(root.Position, GameConfig.Noise.Walkie, player)
			end
		end
	elseif itemId == "Whistle" then
		if onCooldown(player, itemId, item.cooldown) then
			return
		end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and services.NoiseService then
			services.NoiseService:Emit(root.Position, GameConfig.Noise.Whistle, player)
			EventBus.Fire("WhistleBlown", player)
			Net.Event("Caption"):FireAllClients("[" .. player.DisplayName .. " blows a sharp whistle]", "Sound")
		end
	elseif itemId == "Camera" then
		if onCooldown(player, itemId, item.cooldown) then
			return
		end
		Net.Event("ScreenEffect"):FireClient(player, "CameraFlash", { soundId = Assets.Sounds.CameraFlash })
		if services.CreatureService:Flash(player, item.stunTime) then
			Net.Event("Toast"):FireClient(player, "It looked away!", "Success")
		end
	elseif itemId == "CalmTonic" then
		tonicUsed[player] = true
		services.FearService:Reduce(player, item.fearReduction)
		Net.Event("Toast"):FireClient(player, "Warm and calm. Fear reduced.", "Success")
		tool:Destroy()
	end
end

function EquipmentService:Init(registry)
	services = registry

	Net.Event("ToggleLight").OnServerEvent:Connect(function(player)
		local data = services.DataService:Get(player)
		if not data or not enabled then
			return
		end
		local tool = findTool(player, data.Loadout.Light)
		if not tool then
			return
		end
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if tool.Parent ~= player.Character and humanoid then
			humanoid:EquipTool(tool)
			setLight(tool, true)
		elseif toggleLimiter:Allow(player) then
			setLight(tool, not tool:GetAttribute("On"))
		end
	end)

	Net.Event("UseTool").OnServerEvent:Connect(function(player, action)
		if action == "SecondWind" and services.PlayerStateService then
			services.PlayerStateService:TryUseSecondWind(player)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		cooldowns[player] = nil
		tonicUsed[player] = nil
		storyItems[player] = nil
	end)
end

function EquipmentService:GiveLoadout(player: Player)
	local data = services.DataService:Get(player)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not data or not backpack then
		return
	end
	for _, existing in backpack:GetChildren() do
		if existing:IsA("Tool") then
			existing:Destroy()
		end
	end
	local held = heldTool(player)
	if held then
		held:Destroy()
	end

	for _, slot in { "Light", "Tool" } do
		local itemId = data.Loadout[slot]
		if itemId and data.Owned[itemId] then
			local tool = buildTool(player, itemId)
			if tool then
				tool.Parent = backpack
			end
		end
	end
	for itemId in pairs(storyItems[player] or {}) do
		local tool = buildTool(player, itemId)
		if tool then
			tool.Parent = backpack
		end
	end
	self:ApplyCosmetics(player)
end

-- Story items (like the whistle) are extra tools on top of the loadout.
function EquipmentService:GiveStoryItem(player: Player, itemId: string)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack or findTool(player, itemId) then
		return
	end
	local tool = buildTool(player, itemId)
	if tool then
		tool.Parent = backpack
	end
	storyItems[player] = storyItems[player] or {}
	storyItems[player][itemId] = true
end

function EquipmentService:EnableLoadouts()
	enabled = true
	for _, player in Players:GetPlayers() do
		self:GiveLoadout(player)
	end
end

function EquipmentService:ResetRun()
	enabled = false
	table.clear(tonicUsed)
	table.clear(storyItems)
	for _, player in Players:GetPlayers() do
		local backpack = player:FindFirstChildOfClass("Backpack")
		if backpack then
			backpack:ClearAllChildren()
		end
		local held = heldTool(player)
		if held then
			held:Destroy()
		end
	end
end

function EquipmentService:IsEnabled(): boolean
	return enabled
end

function EquipmentService:RefreshLoadout(player: Player)
	if enabled then
		self:GiveLoadout(player)
	end
end

function EquipmentService:ApplyCosmetics(player: Player)
	local data = services.DataService:Get(player)
	local beam = data and Items.Cosmetics[data.EquippedBeam]
	local tool = findTool(player, "Flashlight")
	local light = tool and lightOf(tool)
	if light and beam then
		light.Color = beam.color
	end
end

function EquipmentService:RechargeAll()
	for _, player in Players:GetPlayers() do
		for _, itemId in { "Flashlight", "Lantern" } do
			local tool = findTool(player, itemId)
			if tool then
				tool:SetAttribute("Battery", tool:GetAttribute("MaxBattery"))
			end
		end
	end
end

function EquipmentService:HasLight(player: Player): boolean
	local tool = heldTool(player)
	local light = tool and lightOf(tool)
	return light ~= nil and light.Enabled
end

-- Extra fear recovery from teammates' lit lanterns.
function EquipmentService:TeamCalmAt(player: Player, position: Vector3): number
	local bonus = 0
	for _, other in Players:GetPlayers() do
		if other ~= player then
			local tool = heldTool(other)
			if tool and tool:GetAttribute("ItemId") == "Lantern" and tool:GetAttribute("On") then
				local handle = tool:FindFirstChild("Handle") :: BasePart?
				local item = Items.Equipment.Lantern
				if handle and (handle.Position - position).Magnitude <= item.range then
					bonus += item.teamCalm
				end
			end
		end
	end
	return bonus
end

function EquipmentService:Start()
	-- Batteries drain while lit; lights stutter when The Watcher is close.
	while true do
		task.wait(TICK)
		for _, player in Players:GetPlayers() do
			local tool = heldTool(player)
			local light = tool and lightOf(tool)
			if tool and light and tool:GetAttribute("On") then
				local battery = math.max(0, (tool:GetAttribute("Battery") or 0) - TICK)
				tool:SetAttribute("Battery", battery)
				if battery <= 0 then
					setLight(tool, false)
					Net.Event("Toast"):FireClient(player, "Your light died. Stay close to the others.", "Warning")
				else
					local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
					local threat = root and services.CreatureService:ThreatDistance(root.Position)
					local flicker = (threat and threat < 40) or battery < 15
					light.Enabled = not (flicker and math.random() < 0.35)
				end
			end
		end
	end
end

return EquipmentService
