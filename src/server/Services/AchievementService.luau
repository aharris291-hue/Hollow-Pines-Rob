-- Lifetime stats and the achievements they unlock (with optional Roblox badges).

local BadgeService = game:GetService("BadgeService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Achievements = require(Shared.Config.Achievements)
local Net = require(Shared.Util.Net)
local EventBus = require(script.Parent.Parent.EventBus)

local AchievementService = {}

local services

-- EventBus event -> profile stat it increments.
local EVENT_STATS = {
	ChapterStarted = "ChaptersStarted",
	ChapterCompleted = "ChaptersCompleted",
	FlawlessClear = "FlawlessClears",
	FuseInserted = "FusesInserted",
	TeammateRevived = "Revives",
	WatcherSpotted = "WatcherSpotted",
	NoteRead = "NotesRead",
	Caught = "TimesCaught",
	Chapter2Completed = "Chapter2Clears",
	MapPieceFound = "MapPiecesFound",
	HidFromRanger = "HidFromRanger",
	FlareFired = "FlaresFired",
}

local function check(player: Player)
	local data = services.DataService:Get(player)
	if not data then
		return
	end
	for _, achievement in Achievements do
		if not data.Achievements[achievement.id] and (data.Stats[achievement.stat] or 0) >= achievement.goal then
			services.DataService:Update(player, function(d)
				d.Achievements[achievement.id] = os.time()
				if achievement.reward then
					d.Owned[achievement.reward] = true
				end
			end)
			services.EconomyService:Add(player, achievement.embers, "Achievement_" .. achievement.id, true)
			Net.Event("Toast"):FireClient(player, "Achievement: " .. achievement.name, "Achievement")
			if achievement.badgeId ~= 0 then
				task.spawn(pcall, BadgeService.AwardBadge, BadgeService, player.UserId, achievement.badgeId)
			end
		end
	end
end

function AchievementService:Init(registry)
	services = registry
end

function AchievementService:Start()
	services.DataService.ProfileLoaded:Connect(check)

	EventBus.Event:Connect(function(name, player, amount)
		if not player then
			return
		end
		if name == "LevelUp" then
			check(player) -- Stats.Level is kept in sync by ProgressionService
			return
		end
		local stat = EVENT_STATS[name]
		if stat then
			services.DataService:Update(player, function(data)
				data.Stats[stat] = (data.Stats[stat] or 0) + amount
			end)
			check(player)
		end
	end)
end

return AchievementService
