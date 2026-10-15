local TestKit = require("../TestKit")
local Progression = require("../../src/shared/Util/Progression")
local describe, it, expect = TestKit.describe, TestKit.it, TestKit.expect

describe("Progression", function()
	it("needs more XP for each level", function()
		for level = 1, 20 do
			expect(Progression.xpToNext(level + 1)).toBeGreaterThan(Progression.xpToNext(level))
		end
	end)

	it("levels up and keeps leftover XP", function()
		local need = Progression.xpToNext(1)
		local level, xp, gained = Progression.addXP(1, 0, need + 7)
		expect(level).toBe(2)
		expect(xp).toBe(7)
		expect(gained).toBe(1)
	end)

	it("can gain several levels at once", function()
		local level, _, gained = Progression.addXP(1, 0, 100000)
		expect(level).toBeGreaterThan(5)
		expect(gained).toBe(level - 1)
	end)

	it("caps at the max level", function()
		local level, xp = Progression.addXP(Progression.MaxLevel - 1, 0, 10 ^ 9)
		expect(level).toBe(Progression.MaxLevel)
		expect(xp).toBe(0)
	end)

	it("ignores negative XP", function()
		local level, xp, gained = Progression.addXP(3, 10, -500)
		expect(level).toBe(3)
		expect(xp).toBe(10)
		expect(gained).toBe(0)
	end)

	it("gives bigger rewards every fifth level", function()
		expect(Progression.levelReward(5)).toBeGreaterThan(Progression.levelReward(4))
	end)
end)
