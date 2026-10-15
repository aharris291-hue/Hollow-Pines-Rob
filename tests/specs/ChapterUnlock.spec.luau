local TestKit = require("../TestKit")
local ChapterUnlock = require("../../src/shared/Util/ChapterUnlock")
local Chapters = require("../../src/shared/Config/Chapters")
local describe, it, expect = TestKit.describe, TestKit.it, TestKit.expect

describe("ChapterUnlock", function()
	it("always unlocks Chapter 1", function()
		expect(ChapterUnlock.isUnlocked({ Cleared = {} }, ChapterUnlock.find(Chapters, 1))).toBe(true)
	end)

	it("locks Chapter 2 until Chapter 1 is cleared", function()
		local chapter2 = ChapterUnlock.find(Chapters, 2)
		expect(ChapterUnlock.isUnlocked({ Cleared = {}, FirstClear = false }, chapter2)).toBe(false)
		expect(ChapterUnlock.isUnlocked({ Cleared = { ["1"] = true } }, chapter2)).toBe(true)
	end)

	it("honours the old FirstClear flag for Chapter 1", function()
		expect(ChapterUnlock.isCleared({ FirstClear = true }, 1)).toBe(true)
		expect(ChapterUnlock.isCleared({ FirstClear = true }, 2)).toBe(false)
	end)

	it("rejects unknown chapters and missing profiles", function()
		expect(ChapterUnlock.find(Chapters, 99)).toBe(nil)
		expect(ChapterUnlock.find(Chapters, "2")).toBe(nil)
		expect(ChapterUnlock.isUnlocked(nil, ChapterUnlock.find(Chapters, 2))).toBe(false)
		expect(ChapterUnlock.isUnlocked({}, nil)).toBe(false)
	end)
end)
