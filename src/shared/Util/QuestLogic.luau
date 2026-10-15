-- Daily quest selection and progress. Deterministic per UTC day so every server
-- offers a player the same three quests.

local QuestLogic = {}

function QuestLogic.dayNumber(unixTime: number): number
	return math.floor(unixTime / 86400)
end

-- Small LCG so the result is identical in Roblox and in tests.
local function lcg(seed: number)
	local state = seed % 2147483647
	if state <= 0 then
		state += 2147483646
	end
	return function(): number
		state = (state * 16807) % 2147483647
		return state
	end
end

function QuestLogic.pickDaily(pool, count: number, day: number): { string }
	local nextRandom = lcg(day * 7919 + 17)
	local ids = {}
	for _, quest in pool do
		table.insert(ids, quest.id)
	end
	-- Fisher-Yates using the seeded generator.
	for i = #ids, 2, -1 do
		local j = nextRandom() % i + 1
		ids[i], ids[j] = ids[j], ids[i]
	end
	local picked = {}
	for i = 1, math.min(count, #ids) do
		table.insert(picked, ids[i])
	end
	return picked
end

function QuestLogic.findQuest(pool, questId: string)
	for _, quest in pool do
		if quest.id == questId then
			return quest
		end
	end
	return nil
end

-- Advances every active quest listening to `event`. Returns ids that changed.
function QuestLogic.advance(active, pool, event: string, amount: number): { string }
	local changed = {}
	for questId, state in active do
		local quest = QuestLogic.findQuest(pool, questId)
		if quest and quest.event == event and state.progress < quest.goal then
			state.progress = math.min(state.progress + amount, quest.goal)
			table.insert(changed, questId)
		end
	end
	return changed
end

function QuestLogic.isComplete(state, quest): boolean
	return state.progress >= quest.goal
end

return QuestLogic
