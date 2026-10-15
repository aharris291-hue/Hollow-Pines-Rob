local TestKit = require("../TestKit")
local PuzzleCode = require("../../src/shared/Util/PuzzleCode")
local describe, it, expect = TestKit.describe, TestKit.it, TestKit.expect

describe("PuzzleCode", function()
	it("makes a code whose clues spell it out in order", function()
		local code, clues = PuzzleCode.generate(12345, 3)
		expect(#code).toBe(3)
		local rebuilt = ""
		table.sort(clues, function(a, b)
			return a.order < b.order
		end)
		for _, clue in clues do
			rebuilt ..= tostring(clue.digit)
		end
		expect(rebuilt).toBe(code)
	end)

	it("is stable for a seed and differs across seeds", function()
		expect(PuzzleCode.generate(7, 3)).toBe(PuzzleCode.generate(7, 3))
		local different = false
		for seed = 1, 20 do
			if PuzzleCode.generate(seed, 3) ~= PuzzleCode.generate(seed + 1000, 3) then
				different = true
			end
		end
		expect(different).toBe(true)
	end)

	it("checks attempts, ignoring spaces and dots", function()
		expect(PuzzleCode.check("147", "147")).toBe(true)
		expect(PuzzleCode.check("147", "1 4.7")).toBe(true)
		expect(PuzzleCode.check("147", "148")).toBe(false)
		expect(PuzzleCode.check("147", nil)).toBe(false)
	end)
end)
