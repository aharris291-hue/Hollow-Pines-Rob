-- Noise and hiding. Players make noise by sprinting, splashing through flood
-- water, using the walkie or blowing a whistle; The Ranger hears anything
-- within a noise's radius (Util/Hearing). Standing still inside a hiding spot
-- (a tent) makes a player Hidden.
--
-- Each player's "Noise" attribute (0 quiet, 1 some, 2 loud) drives the HUD
-- indicator so players can see, not just hear, how loud they are.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Hearing = require(Shared.Util.Hearing)

local NoiseService = {}

local NOISE = GameConfig.Noise
local TICK = 0.25
local EMIT_INTERVAL = 0.75 -- footstep noise is re-emitted this often while it lasts

local services
local noises = {}
local lastEmit: { [Player]: number } = {}

local function rootAndHumanoid(player: Player): (BasePart?, Humanoid?)
	local character = player.Character
	if not character then
		return nil, nil
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?, character:FindFirstChildOfClass("Humanoid")
end

local function inAny(position: Vector3, regions): boolean
	for _, region in regions or {} do
		local localPoint = region.cframe:PointToObjectSpace(position)
		local half = region.size / 2
		if math.abs(localPoint.X) <= half.X and math.abs(localPoint.Y) <= half.Y and math.abs(localPoint.Z) <= half.Z then
			return true
		end
	end
	return false
end

function NoiseService:Init(registry)
	services = registry
	Players.PlayerRemoving:Connect(function(player)
		lastEmit[player] = nil
	end)
end

function NoiseService:Emit(position: Vector3, radius: number, source: Player?)
	table.insert(noises, { position = position, radius = radius, time = os.clock(), source = source })
end

function NoiseService:GetNoises()
	return noises
end

function NoiseService:Clear()
	table.clear(noises)
end

function NoiseService:Start()
	while true do
		task.wait(TICK)
		local now = os.clock()
		Hearing.prune(noises, now, NOISE.MemorySeconds)
		local refs = services.ChapterService:GetRefs()
		local active = services.ChapterService:IsGameplayActive()

		for _, player in Players:GetPlayers() do
			local root, humanoid = rootAndHumanoid(player)
			local level = 0
			local hidden = false
			if active and root and humanoid and not player:GetAttribute("Downed") and not player:GetAttribute("Escaped") then
				local moving = humanoid.MoveDirection.Magnitude > 0.1
				local sprinting = moving and humanoid.WalkSpeed > GameConfig.Movement.WalkSpeed + 1
				local wet = refs ~= nil and inAny(root.Position, refs.SplashZones)
				local radius = 0
				if wet and moving then
					radius = if sprinting then NOISE.SplashSprint else NOISE.Splash
				elseif sprinting then
					radius = NOISE.Sprint
				end
				if radius > 0 then
					level = if radius >= NOISE.Sprint then 2 else 1
					if now - (lastEmit[player] or 0) >= EMIT_INTERVAL then
						lastEmit[player] = now
						self:Emit(root.Position, radius, player)
					end
				end
				hidden = not moving and refs ~= nil and inAny(root.Position, refs.HideSpots)
			end
			player:SetAttribute("Noise", level)
			player:SetAttribute("Hidden", if hidden then true else nil)
		end
	end
end

return NoiseService
