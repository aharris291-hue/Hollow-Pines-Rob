local TestKit = require("../TestKit")
local Trust = require("../../src/shared/Util/Trust")
local describe, it, expect = TestKit.describe, TestKit.it, TestKit.expect

local V = {}
V.__index = V
local function vec(x, z)
	return setmetatable({ X = x, Y = 0, Z = z }, V)
end

describe("Trust", function()
	it("treats a player with nobody nearby as alone", function()
		expect(Trust.isAlone(vec(0, 0), {}, 20)).toBe(true)
		expect(Trust.isAlone(vec(0, 0), { vec(30, 0) }, 20)).toBe(true)
		expect(Trust.isAlone(vec(0, 0), { vec(30, 0), vec(10, 10) }, 20)).toBe(false)
	end)

	it("matches a handshake only when both offer to each other in time", function()
		local offers = { b = { target = "a", at = 10 } }
		expect(Trust.handshake(offers, "a", "b", 12, 4)).toBe(true)
		expect(Trust.handshake(offers, "a", "b", 15, 4)).toBe(false)
		expect(Trust.handshake(offers, "c", "b", 12, 4)).toBe(false)
		expect(Trust.handshake({}, "a", "b", 12, 4)).toBe(false)
	end)

	it("solves a sequence pressed in order", function()
		local sequence = Trust.newSequence({ "Chapel", "School", "Mill" })
		expect(sequence:Press("Chapel")).toBe("progress")
		expect(sequence:Press("School")).toBe("progress")
		expect(sequence:Press("Mill")).toBe("done")
		expect(sequence:Press("Chapel")).toBe("done")
	end)

	it("resets on a wrong press but keeps a correct restart", function()
		local sequence = Trust.newSequence({ "Chapel", "School", "Mill" })
		sequence:Press("Chapel")
		expect(sequence:Press("Mill")).toBe("wrong")
		expect(sequence:Progress()).toBe(0)
		sequence:Press("Chapel")
		expect(sequence:Press("Chapel")).toBe("wrong")
		expect(sequence:Progress()).toBe(1)
		expect(sequence:Press("School")).toBe("progress")
	end)
end)
