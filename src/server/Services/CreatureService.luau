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

function CreatureService:Spawn()
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
end

function CreatureService:Despawn()
	if self.watcher then
		self.watcher:Destroy()
		self.watcher = nil
	end
	if self.mimic then
		self.mimic:Destroy()
		self.mimic = nil
	end
end

-- Distance from a position to the nearest visible threat, for the fear system.
function CreatureService:ThreatDistance(position: Vector3): number?
	local watcherPosition = self.watcher and self.watcher:Position()
	if watcherPosition then
		return (watcherPosition - position).Magnitude
	end
	return nil
end

-- Camera flash: makes The Watcher look away if it is in front of the player.
function CreatureService:Flash(player: Player, stunTime: number): boolean
	local watcherPosition = self.watcher and self.watcher:Position()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not watcherPosition or not root then
		return false
	end
	local offset = watcherPosition - root.Position
	local look = looks[player] or root.CFrame.LookVector
	if offset.Magnitude < 45 and look:Dot(offset.Unit) > 0.6 then
		self.watcher:Stun(stunTime)
		EventBus.Fire("WatcherFlashed", player)
		return true
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
		for _, creature in { self.watcher, self.mimic } do
			if creature then
				local ok, err = pcall(creature.Update, creature, dt)
				if not ok then
					warn("[CreatureService] update error: " .. tostring(err))
				end
			end
		end
	end
end

return CreatureService
