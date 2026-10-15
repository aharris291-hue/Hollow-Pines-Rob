local TestKit = require("../TestKit")
local BestTimes = require("../../src/shared/Util/BestTimes")
local describe, it, expect = TestKit.describe, TestKit.it, TestKit.expect

describe("BestTimes", function()
	it("keeps whole seconds and rejects nonsense", function()
		expect(BestTimes.sanitize(245.9)).toBe(245)
		expect(BestTimes.sanitize(0)).toBe(nil)
		expect(BestTimes.sanitize(-5)).toBe(nil)
		expect(BestTimes.sanitize(0 / 0)).toBe(nil)
		expect(BestTimes.sanitize(10 ^ 9)).toBe(nil)
	end)

	it("counts the first time and faster times as a best", function()
		expect(BestTimes.isBetter(nil, 300)).toBe(true)
		expect(BestTimes.isBetter(0, 300)).toBe(true)
		expect(BestTimes.isBetter(320, 300)).toBe(true)
		expect(BestTimes.isBetter(300, 300)).toBe(false)
		expect(BestTimes.isBetter(280, 300)).toBe(false)
	end)

	it("formats minutes and hours", function()
		expect(BestTimes.format(245)).toBe("4:05")
		expect(BestTimes.format(59)).toBe("0:59")
		expect(BestTimes.format(3723)).toBe("1:02:03")
	end)

	it("ranks the fastest first and stops at the limit", function()
		local lines = BestTimes.lines({
			{ name = "Sam", seconds = 400 },
			{ name = "Ava", seconds = 250 },
			{ name = "Max", seconds = 250 },
			{ name = "Zed", seconds = 900 },
		}, 3)
		expect(#lines).toBe(3)
		expect(lines[1]).toBe("1. Ava  4:10")
		expect(lines[2]).toBe("2. Max  4:10")
		expect(lines[3]).toBe("3. Sam  6:40")
	end)
end)
