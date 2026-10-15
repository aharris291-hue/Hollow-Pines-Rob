-- Server-authoritative fear. Darkness, being alone and nearby creatures raise it;
-- light, teammates and the powered ranger station calm it down.
-- Fear is published as the "Fear" player attribute so every client can show the
-- whole team's state, and the owner's client drives its screen effects from it.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local FearMath = require(Shared.Util.FearMath)
local EventBus = require(script.Parent.Parent.EventBus)

local FearService = {}

local CONFIG = GameConfig.Fear
local TICK = 0.25
local TEAM_TIME_CHUNK = 10

local services
local fear: { [Player]: number } = {}
local teamTime: { [Player]: number } = {}

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function publish(player: Player)
	local value = fear[player] or 0
	player:SetAttribute("Fear", math.floor(value + 0.5))
	player:SetAttribute("FearTier", FearMath.tier(value, CONFIG))
end

local function teammatesNear(player: Player, position: Vector3): number
	local count = 0
	for _, other in Players:GetPlayers() do
		if other ~= player and not other:GetAttribute("Downed") then
			local root = rootOf(other)
			if root and (root.Position - position).Magnitude <= CONFIG.AloneRadius then
				count += 1
			end
		end
	end
	return count
end

function FearService:Init(registry)
	services = registry
	Players.PlayerRemoving:Connect(function(player)
		fear[player] = nil
		teamTime[player] = nil
	end)
end

function FearService:Get(player: Player): number
	return fear[player] or 0
end

function FearService:Set(player: Player, value: number)
	fear[player] = math.clamp(value, 0, CONFIG.Max)
	publish(player)
end

function FearService:Spike(player: Player, amount: number)
	local calmer = services.SettingsService:Get(player, "CalmerScares")
	fear[player] = FearMath.spike(fear[player] or 0, amount, CONFIG, calmer)
	publish(player)
end

function FearService:Reduce(player: Player, amount: number)
	self:Set(player, (fear[player] or 0) - amount)
end

function FearService:ResetAll()
	for _, player in Players:GetPlayers() do
		self:Set(player, 0)
	end
end

function FearService:Start()
	while true do
		task.wait(TICK)
		if services.ChapterService:IsGameplayActive() then
			for _, player in Players:GetPlayers() do
				local root = rootOf(player)
				if root and not player:GetAttribute("Downed") then
					if player:GetAttribute("Escaped") then
						self:Reduce(player, CONFIG.SafeZoneRecover * TICK)
					else
						local position = root.Position
						local near = teammatesNear(player, position)
						local situation = {
							hasLight = services.EquipmentService:HasLight(player),
							teammatesNear = near,
							creatureDistance = services.CreatureService:ThreatDistance(position),
							inSafeZone = services.ChapterService:IsInSafeZone(position),
							calmerScares = services.SettingsService:Get(player, "CalmerScares"),
							teamCalmBonus = services.EquipmentService:TeamCalmAt(player, position),
						}
						fear[player] = FearMath.step(fear[player] or 0, situation, CONFIG, TICK)
						publish(player)

						if near > 0 then
							teamTime[player] = (teamTime[player] or 0) + TICK
							if teamTime[player] >= TEAM_TIME_CHUNK then
								teamTime[player] -= TEAM_TIME_CHUNK
								EventBus.Fire("TimeWithTeam", player, TEAM_TIME_CHUNK)
							end
						end
					end
				end
			end
		end
	end
end

return FearService
