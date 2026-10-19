-- Lobby queues, one per chapter. Players pick a chapter and press Play; when a
-- queue fills (or its countdown ends) that group is teleported together into a
-- private server of the chapter's place. Locked chapters are refused here, not
-- only hidden in the UI.

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Chapters = require(Shared.Config.Chapters)
local ChapterUnlock = require(Shared.Util.ChapterUnlock)
local Net = require(Shared.Util.Net)
local RateLimit = require(Shared.Util.RateLimit)

local MatchmakingService = {}

type Queue = { players: { Player }, countdown: number?, launching: boolean }

local services
local queues: { [number]: Queue } = {}
local limiter = RateLimit.new(1)

for _, chapter in Chapters do
	queues[chapter.id] = { players = {}, countdown = nil, launching = false }
end

local function queueOf(player: Player): (number?, Queue?)
	for id, queue in queues do
		if table.find(queue.players, player) then
			return id, queue
		end
	end
	return nil, nil
end

local function broadcast()
	local summary = {}
	for id, queue in queues do
		local names = {}
		for _, player in queue.players do
			table.insert(names, player.DisplayName)
		end
		summary[id] = { names = names, countdown = queue.countdown }
	end
	for _, player in Players:GetPlayers() do
		local chapterId = queueOf(player)
		Net.Event("QueueUpdated"):FireClient(player, {
			inQueue = chapterId ~= nil,
			chapter = chapterId,
			queues = summary,
			max = GameConfig.Party.MaxPlayers,
		})
	end
end

local function remove(player: Player)
	local _, queue = queueOf(player)
	if queue then
		table.remove(queue.players, table.find(queue.players, player) :: number)
		if #queue.players == 0 then
			queue.countdown = nil
		end
	end
	broadcast()
end

local function launch(chapterId: number, queue: Queue)
	queue.launching = true
	local group = table.clone(queue.players)
	table.clear(queue.players)
	queue.countdown = nil
	broadcast()

	local chapter = ChapterUnlock.find(Chapters, chapterId)
	local placeId = GameConfig.Places[chapter.place] or 0
	if placeId == 0 then
		-- One-place mode: a reserved server of this same place runs the chapter.
		placeId = game.PlaceId
	end
	if placeId == 0 then
		for _, player in group do
			Net.Event("Toast"):FireClient(player, "Groups can only leave for the forest in the published game.", "Info")
		end
		queue.launching = false
		return
	end

	local ok, err = pcall(function()
		local code = TeleportService:ReserveServer(placeId)
		local options = Instance.new("TeleportOptions")
		options.ReservedServerAccessCode = code
		options:SetTeleportData({ partySize = #group, chapter = chapterId })
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
	queue.launching = false
end

function MatchmakingService:Init(registry)
	services = registry

	Net.Event("JoinQueue").OnServerEvent:Connect(function(player, chapterId)
		if not limiter:Allow(player) then
			return
		end
		chapterId = if chapterId == nil then 1 else chapterId
		local chapter = ChapterUnlock.find(Chapters, chapterId)
		local queue = chapter and queues[chapter.id]
		if not chapter or not queue or queue.launching then
			return
		end
		if not ChapterUnlock.isUnlocked(services.DataService:Get(player), chapter) then
			Net.Event("Toast"):FireClient(player, string.format("Escape Chapter %d first to unlock this chapter.", chapter.requires), "Warning")
			return
		end
		local current = queueOf(player)
		if current == chapter.id then
			return
		elseif current then
			remove(player) -- switching chapters
		end
		if #queue.players >= GameConfig.Party.MaxPlayers then
			Net.Event("Toast"):FireClient(player, "The group is full. Next trip leaves soon!", "Info")
			return
		end
		table.insert(queue.players, player)
		queue.countdown = queue.countdown or GameConfig.Party.QueueCountdown
		if #queue.players >= GameConfig.Party.MaxPlayers then
			queue.countdown = math.min(queue.countdown :: number, GameConfig.Party.FullQueueCountdown)
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
		local changed = false
		for id, queue in queues do
			if queue.countdown and not queue.launching then
				queue.countdown -= 1
				changed = true
				if queue.countdown <= 0 and #queue.players >= GameConfig.Party.MinPlayers then
					task.spawn(launch, id, queue)
				end
			end
		end
		if changed then
			broadcast()
		end
	end
end

return MatchmakingService
