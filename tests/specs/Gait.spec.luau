local TestKit = require("../TestKit")
local Gait = require("../../src/shared/Util/Gait")
local describe, it, expect = TestKit.describe, TestKit.it, TestKit.expect

local STYLE = { stride = 8, legSwing = 30, armSwing = 20, bob = 0.4, runSpeed = 16 }

local function vec(x, z)
	return { X = x, Y = 0, Z = z }
end

local function near(a, b)
	return math.abs(a - b) < 1e-6
end

describe("Gait", function()
	it("advances the stride with speed and stays put when standing", function()
		expect(Gait.advance(0, 0, 1, STYLE)).toBe(0)
		-- 8 studs at 8 studs/s is one full step: back to the start of the cycle.
		expect(near(Gait.advance(0, 8, 1, STYLE), 0)).toBe(true)
		expect(near(Gait.advance(0, 4, 1, STYLE), math.pi)).toBe(true)
	end)

	it("eases towards a full stride and never past it", function()
		local amount = Gait.blend(0, 32, 0.1, STYLE, 8)
		expect(amount > 0 and amount < 1).toBe(true)
		for _ = 1, 100 do
			amount = Gait.blend(amount, 32, 0.1, STYLE, 8)
		end
		expect(near(amount, 1)).toBe(true)
		expect(Gait.blend(1, 0, 10, STYLE, 8) < 0.01).toBe(true)
	end)

	it("swings legs and arms in opposite directions", function()
		local pose = Gait.pose(math.pi / 2, 1, STYLE)
		expect(near(pose.leg, math.rad(30))).toBe(true)
		expect(near(pose.arm, -math.rad(20))).toBe(true)
		expect(near(pose.bob, 0.4)).toBe(true)
		local still = Gait.pose(math.pi / 2, 0, STYLE)
		expect(still.leg).toBe(0)
		expect(still.bob).toBe(0)
	end)

	it("treats a big jump in one frame as a teleport, not a sprint", function()
		expect(Gait.speedBetween(vec(0, 0), vec(3, 4), 0.5, 10)).toBe(10)
		expect(Gait.speedBetween(vec(0, 0), vec(30, 40), 0.5, 10)).toBe(0)
		expect(Gait.speedBetween(vec(0, 0), vec(1, 0), 0, 10)).toBe(0)
	end)
end)
