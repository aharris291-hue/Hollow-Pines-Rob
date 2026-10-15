local TestKit = require("../TestKit")
local QuestLogic = require("../../src/shared/Util/QuestLogic")
local describe, it, expect = TestKit.describe, TestKit.it, TestKit.expect

local POOL = {
	{ id = "A", event = "FuseInserted", goal = 5 },
	{ id = "B", event = "TeammateRevived", goal = 2 },
	{ id = "C", event = "ChapterCompleted", goal = 1 },
	{ id = "D", event = "NoteRead", goal = 6 },
	{ id = "E", event = "WatcherSpotted", goal = 3 },
}

describe("QuestLogic.pickDaily", function()
	it("is deterministic for a day", function()
		local a = QuestLogic.pickDaily(POOL, 3, 20000)
		local b = QuestLogic.pickDaily(POOL, 3, 20000)
		expect(table.concat(a, ",")).toBe(table.concat(b, ","))
	end)

	it("picks distinct quests", function()
		local picked = QuestLogic.pickDaily(POOL, 3, 20001)
		expect(#picked).toBe(3)
		local seen = {}
		for _, id in picked do
			expect(seen[id]).toBe(nil)
			seen[id] = true
		end
	end)

	it("varies between days", function()
		local different = false
		local first = table.concat(QuestLogic.pickDaily(POOL, 3, 1), ",")
		for day = 2, 10 do
			if table.concat(QuestLogic.pickDaily(POOL, 3, day), ",") ~= first then
				different = true
			end
		end
		expect(different).toBe(true)
	end)

	it("computes the UTC day number", function()
		expect(QuestLogic.dayNumber(86400 * 3 + 5)).toBe(3)
	end)
end)

describe("QuestLogic.advance", function()
	it("advances matching quests and caps at the goal", function()
		local active = { A = { progress = 4, claimed = false }, B = { progress = 0, claimed = false } }
		local changed = QuestLogic.advance(active, POOL, "FuseInserted", 3)
		expect(#changed).toBe(1)
		expect(active.A.progress).toBe(5)
		expect(active.B.progress).toBe(0)
		expect(QuestLogic.isComplete(active.A, POOL[1])).toBe(true)
	end)

	it("does not report already finished quests", function()
		local active = { C = { progress = 1, claimed = false } }
		expect(#QuestLogic.advance(active, POOL, "ChapterCompleted", 1)).toBe(0)
	end)
end)
