-- Lobby queue. Players press Play; when the queue fills (or its countdown ends)
-- the group is teleported together into a private Chapter 1 server.

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Net = require(Shared.Util.Net)
local RateLimit = require(Shared.Util.RateLimit)

local MatchmakingService = {}

local queue: { Player } = {}
local countdown: number? = nil
local launching = false
local limiter = RateLimit.new(1)

local function broadcast()
	local names = {}
	for _, player in queue do
		table.insert(names, player.DisplayName)
	end
	for _, player in Players:GetPlayers() do
		Net.Event("QueueUpdated"):FireClient(player, {
			inQueue = table.find(queue, player) ~= nil,
			names = names,
			max = GameConfig.Party.MaxPlayers,
			countdown = countdown,
		})
	end
end

local function remove(player: Player)
	local index = table.find(queue, player)
	if index then
		table.remove(queue, index)
	end
	if #queue == 0 then
		countdown = nil
	end
	broadcast()
end

local function launch()
	launching = true
	local group = table.clone(queue)
	table.clear(queue)
	countdown = nil
	broadcast()

	local placeId = GameConfig.Places.Chapter1
	if placeId == 0 then
		for _, player in group do
			Net.Event("Toast"):FireClient(player, "Chapter 1 place id is not set yet (see docs/DEPLOYMENT.md)", "Error")
		end
		launching = false
		return
	end

	local ok, err = pcall(function()
		local code = TeleportService:ReserveServer(placeId)
		local options = Instance.new("TeleportOptions")
		options.ReservedServerAccessCode = code
		options:SetTeleportData({ partySize = #group, chapter = 1 })
		TeleportService:TeleportAsync(placeId, group, options)
	end)
	if not ok then
		warn("[Matchmaking] teleport failed: " .. tostring(err))
		for _, player in group do
			if player.Parent then
				Net.Event("Toast"):FireClient(player, "Couldn't reach the forest. Try again!", "Error")
			end
		end
	end
	launching = false
end

function MatchmakingService:Init()
	Net.Event("JoinQueue").OnServerEvent:Connect(function(player)
		if launching or not limiter:Allow(player) or table.find(queue, player) then
			return
		end
		if #queue >= GameConfig.Party.MaxPlayers then
			Net.Event("Toast"):FireClient(player, "The group is full. Next trip leaves soon!", "Info")
			return
		end
		table.insert(queue, player)
		if not countdown then
			countdown = GameConfig.Party.QueueCountdown
		end
		if #queue >= GameConfig.Party.MaxPlayers then
			countdown = math.min(countdown, GameConfig.Party.FullQueueCountdown)
		end
		broadcast()
	end)

	Net.Event("LeaveQueue").OnServerEvent:Connect(remove)
	Players.PlayerRemoving:Connect(remove)
	Players.PlayerAdded:Connect(function()
		task.defer(broadcast)
	end)

	TeleportService.TeleportInitFailed:Connect(function(player, result, message)
		warn("[Matchmaking] teleport init failed for " .. player.Name .. ": " .. tostring(result) .. " " .. tostring(message))
		Net.Event("Toast"):FireClient(player, "Teleport failed. Press Play to try again.", "Error")
	end)
end

function MatchmakingService:Start()
	while true do
		task.wait(1)
		if countdown and not launching then
			countdown -= 1
			if countdown <= 0 and #queue >= GameConfig.Party.MinPlayers then
				task.spawn(launch)
			else
				broadcast()
			end
		end
	end
end

return MatchmakingService
