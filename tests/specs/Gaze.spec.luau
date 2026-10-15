local TestKit = require("../TestKit")
local Gaze = require("../../src/shared/Util/Gaze")
local describe, it, expect = TestKit.describe, TestKit.it, TestKit.expect

local function vec(x, z)
	return { X = x, Y = 0, Z = z }
end

describe("Gaze", function()
	it("sees players inside the beam and within range", function()
		expect(Gaze.inBeam(vec(0, 0), 0, 15, 100, vec(0, 50))).toBe(true)
		expect(Gaze.inBeam(vec(0, 0), 90, 15, 100, vec(50, 2))).toBe(true)
		expect(Gaze.inBeam(vec(0, 0), 0, 15, 100, vec(50, 2))).toBe(false)
		expect(Gaze.inBeam(vec(0, 0), 0, 15, 100, vec(0, 150))).toBe(false)
	end)

	it("wraps angles around 180 degrees", function()
		expect(Gaze.inBeam(vec(0, 0), 175, 15, 100, vec(-5, -50))).toBe(true)
		expect(Gaze.inBeam(vec(0, 0), -175, 15, 100, vec(5, -50))).toBe(true)
	end)

	it("builds exposure while seen and drains it while hidden", function()
		local exposure, caught = Gaze.step(0, true, 1, 1.5, 1.6)
		expect(exposure).toBe(1)
		expect(caught).toBe(false)
		exposure, caught = Gaze.step(exposure, false, 0.5, 1.5, 1.6)
		expect(exposure).toBe(0.25)
		exposure, caught = Gaze.step(1.5, true, 0.2, 1.5, 1.6)
		expect(caught).toBe(true)
		expect(exposure).toBe(0)
	end)
end)
