-- Owns the creatures for the current chapter run and ticks them.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Assets = require(Shared.Config.Assets)
local Net = require(Shared.Util.Net)
local RateLimit = require(Shared.Util.RateLimit)
local EventBus = require(script.Parent.Parent.EventBus)

local Creatures = script.Parent.Parent:WaitForChild("Creatures")
local Watcher = require(Creatures.Watcher)
local Mimic = require(Creatures.Mimic)
local Ranger = require(Creatures.Ranger)

local CreatureService = {}

local TICK = 0.1

local services
local looks: { [Player]: Vector3 } = {}
local lookLimiter = RateLimit.new(0.1)

-- Players the creatures may notice: in the world, not downed, not already safe.
local function activeTargets(): { Player }
	local targets = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 and not player:GetAttribute("Downed") and not player:GetAttribute("Escaped") then
			table.insert(targets, player)
		end
	end
	return targets
end

function CreatureService:Init(registry)
	services = registry

	Net.Event("ReportLook").OnServerEvent:Connect(function(player, direction)
		if typeof(direction) ~= "Vector3" or not lookLimiter:Allow(player) then
			return
		end
		local magnitude = direction.Magnitude
		if magnitude > 0.5 and magnitude < 1.5 then
			looks[player] = direction.Unit
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		looks[player] = nil
		lookLimiter:Forget(player)
	end)
end

function CreatureService:Spawn(chapterId: number?)
	self:Despawn()
	self.watcher = Watcher.new({
		getTargets = activeTargets,
		getLook = function(player)
			return looks[player]
		end,
		onSpotted = function(player)
			EventBus.Fire("WatcherSpotted", player)
			services.FearService:Spike(player, 12)
			Net.Event("ScreenEffect"):FireClient(player, "WatcherSting", { soundId = Assets.Sounds.WatcherSting })
		end,
		onCatch = function(player)
			services.PlayerStateService:Down(player, "The Watcher")
		end,
	})
	self.mimic = Mimic.new({
		getTargets = activeTargets,
		onFearSpike = function(player, amount)
			services.FearService:Spike(player, amount)
		end,
	})
	if (chapterId or 1) >= 2 then
		local refs = services.ChapterService:GetRefs()
		self.ranger = Ranger.new({
			getTargets = activeTargets,
			getNoises = function()
				return services.NoiseService:GetNoises()
			end,
			hasLight = function(player)
				return services.EquipmentService:HasLight(player)
			end,
			isSafe = function(position)
				return services.ChapterService:IsInSafeZone(position)
			end,
			patrolPoints = refs.PatrolPoints,
			onSpotted = function(player)
				EventBus.Fire("RangerSpotted", player)
				services.FearService:Spike(player, 18)
				Net.Event("ScreenEffect"):FireClient(player, "RangerSpotted", { soundId = Assets.Sounds.WatcherSting })
			end,
			onLost = function(player, hidden)
				if hidden then
					EventBus.Fire("HidFromRanger", player)
					Net.Event("Toast"):FireClient(player, "It lost you. Stay still...", "Success")
				end
			end,
			onHeard = function(noise)
				if noise.source and typeof(noise.source) == "Instance" and noise.source:IsA("Player") then
					Net.Event("Caption"):FireClient(noise.source, "[The lantern swings towards the sound you made]", "Sound")
				end
			end,
			onCatch = function(player)
				services.PlayerStateService:Down(player, "The Ranger")
			end,
		})
	end
end

function CreatureService:Despawn()
	for _, key in { "watcher", "mimic", "ranger" } do
		if self[key] then
			self[key]:Destroy()
			self[key] = nil
		end
	end
end

-- Distance from a position to the nearest visible threat, for the fear system.
function CreatureService:ThreatDistance(position: Vector3): number?
	local nearest = nil
	for _, creature in { self.watcher, self.ranger } do
		local creaturePosition = creature and creature:Position()
		if creaturePosition then
			local distance = (creaturePosition - position).Magnitude
			if not nearest or distance < nearest then
				nearest = distance
			end
		end
	end
	return nearest
end

-- Camera flash: makes a creature in front of the player look away.
function CreatureService:Flash(player: Player, stunTime: number): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end
	local look = looks[player] or root.CFrame.LookVector
	for _, creature in { self.watcher, self.ranger } do
		local creaturePosition = creature and creature:Position()
		if creaturePosition then
			local offset = creaturePosition - root.Position
			if offset.Magnitude < 45 and look:Dot(offset.Unit) > 0.6 then
				creature:Stun(stunTime)
				EventBus.Fire("WatcherFlashed", player)
				return true
			end
		end
	end
	return false
end

function CreatureService:Start()
	local last = os.clock()
	while true do
		task.wait(TICK)
		local now = os.clock()
		local dt = now - last
		last = now
		for _, key in { "watcher", "mimic", "ranger" } do
			local creature = self[key]
			if creature then
				local ok, err = pcall(creature.Update, creature, dt)
				if not ok then
					warn("[CreatureService] " .. key .. " update error: " .. tostring(err))
				end
			end
		end
	end
end

return CreatureService
