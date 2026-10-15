-- Daily quests: three per UTC day, advanced by EventBus events, claimed from the
-- Quests menu.

local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Quests = require(Shared.Config.Quests)
local QuestLogic = require(Shared.Util.QuestLogic)
local ChapterUnlock = require(Shared.Util.ChapterUnlock)
local Net = require(Shared.Util.Net)
local EventBus = require(script.Parent.Parent.EventBus)

local QuestService = {}

local services

local function refreshDaily(player: Player)
	local today = QuestLogic.dayNumber(os.time())
	services.DataService:Update(player, function(data)
		if data.Quests.Day == today then
			return
		end
		data.Quests.Day = today
		data.Quests.Active = {}
		-- Quests for a chapter the player can't play yet are left out of the roll.
		local pool = {}
		for _, quest in Quests.Pool do
			if not quest.chapter or quest.chapter == 1 or ChapterUnlock.isCleared(data, quest.chapter - 1) then
				table.insert(pool, quest)
			end
		end
		for _, questId in QuestLogic.pickDaily(pool, Quests.DailyCount, today) do
			data.Quests.Active[questId] = { progress = 0, claimed = false }
		end
	end)
end

function QuestService:Init(registry)
	services = registry

	Net.Event("ClaimQuest").OnServerEvent:Connect(function(player, questId)
		if type(questId) == "string" then
			self:Claim(player, questId)
		end
	end)
end

function QuestService:Start()
	services.DataService.ProfileLoaded:Connect(function(player)
		refreshDaily(player)
	end)

	EventBus.Event:Connect(function(name, player, amount)
		if not player then
			return
		end
		local data = services.DataService:Get(player)
		if not data then
			return
		end
		local changed = QuestLogic.advance(data.Quests.Active, Quests.Pool, name, amount)
		for _, questId in changed do
			local quest = QuestLogic.findQuest(Quests.Pool, questId)
			if QuestLogic.isComplete(data.Quests.Active[questId], quest) then
				Net.Event("Toast"):FireClient(player, "Quest complete: " .. quest.text, "Quest")
			end
		end
		if #changed > 0 then
			services.DataService:Replicate(player)
		end
	end)

	-- Servers can live across midnight UTC.
	task.spawn(function()
		while true do
			task.wait(60)
			for _, player in Players:GetPlayers() do
				if services.DataService:Get(player) then
					refreshDaily(player)
				end
			end
		end
	end)
end

function QuestService:Claim(player: Player, questId: string): boolean
	local data = services.DataService:Get(player)
	local state = data and data.Quests.Active[questId]
	local quest = QuestLogic.findQuest(Quests.Pool, questId)
	if not state or not quest or state.claimed or not QuestLogic.isComplete(state, quest) then
		return false
	end
	services.DataService:Update(player, function()
		state.claimed = true
	end)
	services.EconomyService:Add(player, quest.embers, "Quest_" .. questId, true)
	services.ProgressionService:AddXP(player, quest.xp)
	Net.Event("Toast"):FireClient(player, string.format("+%d Embers, +%d XP", quest.embers, quest.xp), "Success")
	return true
end

return QuestService
