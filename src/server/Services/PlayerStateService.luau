-- Movement (walk, sprint, stamina, panic slowdown) and the downed/revive loop.
-- Nobody dies in Hollow Pines: a caught player is downed, a teammate can help
-- them up, and otherwise they wake at the last checkpoint.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Net = require(Shared.Util.Net)
local Signal = require(Shared.Util.Signal)
local EventBus = require(script.Parent.Parent.EventBus)

local PlayerStateService = {}

PlayerStateService.Downed = Signal.new() -- (player, byWhat)

local MOVE = GameConfig.Movement
local DOWNED = GameConfig.Downed
local TICK = 0.1

local services
local sprinting: { [Player]: boolean } = {}
local stamina: { [Player]: number } = {}
local downedAt: { [Player]: number } = {}
local revivePrompts: { [Player]: ProximityPrompt } = {}
local secondWindUsed: { [Player]: boolean } = {}

local function humanoidOf(player: Player): Humanoid?
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function clearDowned(player: Player)
	downedAt[player] = nil
	player:SetAttribute("Downed", nil)
	if revivePrompts[player] then
		revivePrompts[player]:Destroy()
		revivePrompts[player] = nil
	end
	local humanoid = humanoidOf(player)
	if humanoid then
		humanoid.JumpHeight = 7.2
		humanoid.JumpPower = 50
	end
	Net.Event("DownedState"):FireClient(player, { downed = false })
end

function PlayerStateService:Init(registry)
	services = registry

	Net.Event("SetSprinting").OnServerEvent:Connect(function(player, value)
		sprinting[player] = value == true
	end)

	Players.PlayerRemoving:Connect(function(player)
		sprinting[player] = nil
		stamina[player] = nil
		downedAt[player] = nil
		revivePrompts[player] = nil
		secondWindUsed[player] = nil
	end)
end

function PlayerStateService:Start()
	local function hook(player: Player)
		player.CharacterAdded:Connect(function(character)
			stamina[player] = MOVE.StaminaMax
			downedAt[player] = nil
			player:SetAttribute("Downed", nil)
			local humanoid = character:WaitForChild("Humanoid") :: Humanoid
			humanoid.WalkSpeed = MOVE.WalkSpeed
			humanoid.BreakJointsOnDeath = false
		end)
	end
	Players.PlayerAdded:Connect(hook)
	for _, player in Players:GetPlayers() do
		hook(player)
	end

	while true do
		task.wait(TICK)
		local now = os.clock()
		for _, player in Players:GetPlayers() do
			local humanoid = humanoidOf(player)
			if humanoid then
				if downedAt[player] then
					humanoid.WalkSpeed = 0
					if now - downedAt[player] >= DOWNED.BleedOutTime then
						self:RespawnAtCheckpoint(player)
					end
				else
					local moving = humanoid.MoveDirection.Magnitude > 0.1
					local current = stamina[player] or MOVE.StaminaMax
					local wantsSprint = sprinting[player] and moving and current > 0
					if wantsSprint then
						current = math.max(0, current - MOVE.StaminaDrain * TICK)
					else
						current = math.min(MOVE.StaminaMax, current + MOVE.StaminaRegen * TICK)
					end
					stamina[player] = current
					player:SetAttribute("Stamina", math.floor(current))

					local speed = if wantsSprint then MOVE.SprintSpeed else MOVE.WalkSpeed
					if player:GetAttribute("FearTier") == "Panicked" then
						speed *= GameConfig.Fear.PanicWalkSpeedMultiplier
					end
					humanoid.WalkSpeed = speed
				end
			end
		end
	end
end

function PlayerStateService:IsDowned(player: Player): boolean
	return downedAt[player] ~= nil
end

function PlayerStateService:Down(player: Player, byWhat: string)
	if downedAt[player] or player:GetAttribute("Escaped") then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = humanoidOf(player)
	if not root or not humanoid then
		return
	end

	downedAt[player] = os.clock()
	player:SetAttribute("Downed", true)
	humanoid.WalkSpeed = 0
	humanoid.JumpHeight = 0
	humanoid.JumpPower = 0
	services.FearService:Set(player, GameConfig.Fear.Max)
	EventBus.Fire("Caught", player)
	PlayerStateService.Downed:Fire(player, byWhat)

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Help up"
	prompt.ObjectText = player.DisplayName
	prompt.HoldDuration = DOWNED.ReviveTime
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 9
	prompt.Parent = root
	revivePrompts[player] = prompt
	prompt.Triggered:Connect(function(helper)
		if helper ~= player and not downedAt[helper] then
			self:Revive(player, helper)
		end
	end)

	local data = services.DataService:Get(player)
	Net.Event("DownedState"):FireClient(player, {
		downed = true,
		by = byWhat,
		bleedOut = DOWNED.BleedOutTime,
		secondWinds = data and data.SecondWinds or 0,
		secondWindUsed = secondWindUsed[player] == true,
	})
	for _, other in Players:GetPlayers() do
		if other ~= player then
			Net.Event("Toast"):FireClient(other, player.DisplayName .. " was caught! Help them up!", "Warning")
		end
	end
end

function PlayerStateService:Revive(player: Player, helper: Player?)
	if not downedAt[player] then
		return
	end
	clearDowned(player)
	services.FearService:Set(player, DOWNED.RespawnFear)
	if helper then
		EventBus.Fire("TeammateRevived", helper)
		Net.Event("Toast"):FireClient(player, helper.DisplayName .. " helped you up!", "Success")
	end
end

function PlayerStateService:TryUseSecondWind(player: Player): boolean
	if not downedAt[player] or secondWindUsed[player] then
		return false
	end
	local data = services.DataService:Get(player)
	if not data or data.SecondWinds <= 0 then
		return false
	end
	services.DataService:Update(player, function(d)
		d.SecondWinds -= 1
	end)
	secondWindUsed[player] = true
	self:Revive(player, nil)
	return true
end

function PlayerStateService:RespawnAtCheckpoint(player: Player)
	clearDowned(player)
	local character = player.Character
	local checkpoint = services.ChapterService:GetCheckpoint()
	if character and checkpoint then
		character:PivotTo(checkpoint * CFrame.new(math.random(-3, 3), 0, math.random(-3, 3)))
	end
	services.FearService:Set(player, DOWNED.RespawnFear)
	Net.Event("Toast"):FireClient(player, "You wake up somewhere familiar...", "Info")
end

function PlayerStateService:ResetRun()
	table.clear(secondWindUsed)
	for _, player in Players:GetPlayers() do
		if downedAt[player] then
			clearDowned(player)
		end
		player:SetAttribute("Escaped", nil)
	end
end

return PlayerStateService
