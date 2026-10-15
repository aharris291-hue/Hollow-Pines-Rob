local TestKit = require("../TestKit")
local FearMath = require("../../src/shared/Util/FearMath")
local describe, it, expect = TestKit.describe, TestKit.it, TestKit.expect

local CONFIG = {
	Max = 100,
	DarknessGain = 1.2,
	AloneGain = 1.5,
	CreatureNearGain = 6,
	LightRecover = 1.0,
	TeammateRecover = 1.5,
	SafeZoneRecover = 6,
	CreatureRadius = 60,
	Uneasy = 35,
	Scared = 65,
	Panicked = 90,
	CalmModeMultiplier = 0.5,
}

local function situation(overrides)
	local base = { hasLight = true, teammatesNear = 1, creatureDistance = nil, inSafeZone = false, calmerScares = false }
	for key, value in overrides or {} do
		base[key] = value
	end
	return base
end

describe("FearMath.step", function()
	it("rises alone in the dark", function()
		local fear = FearMath.step(10, situation({ hasLight = false, teammatesNear = 0 }), CONFIG, 1)
		expect(fear).toBeNear(10 + 1.2 + 1.5)
	end)

	it("falls with a light and a teammate", function()
		expect(FearMath.step(10, situation(), CONFIG, 1)).toBeNear(7.5)
	end)

	it("rises faster the closer a creature is", function()
		local far = FearMath.step(50, situation({ creatureDistance = 50 }), CONFIG, 1)
		local near = FearMath.step(50, situation({ creatureDistance = 5 }), CONFIG, 1)
		expect(near).toBeGreaterThan(far)
	end)

	it("ignores creatures outside the radius", function()
		expect(FearMath.step(50, situation({ creatureDistance = 200 }), CONFIG, 1)).toBeNear(47.5)
	end)

	it("recovers fast in a safe zone even alone in the dark", function()
		expect(FearMath.step(50, situation({ inSafeZone = true, hasLight = false, teammatesNear = 0 }), CONFIG, 1)).toBeNear(44)
	end)

	it("halves gains with calmer scares", function()
		local normal = FearMath.step(20, situation({ hasLight = false, teammatesNear = 0 }), CONFIG, 1) - 20
		local calm = FearMath.step(20, situation({ hasLight = false, teammatesNear = 0, calmerScares = true }), CONFIG, 1) - 20
		expect(calm).toBeNear(normal / 2)
	end)

	it("stays within 0 and Max", function()
		expect(FearMath.step(99.9, situation({ hasLight = false, teammatesNear = 0, creatureDistance = 0 }), CONFIG, 10)).toBe(100)
		expect(FearMath.step(0.5, situation({ inSafeZone = true }), CONFIG, 10)).toBe(0)
	end)
end)

describe("FearMath.tier", function()
	it("maps thresholds", function()
		expect(FearMath.tier(0, CONFIG)).toBe("Calm")
		expect(FearMath.tier(35, CONFIG)).toBe("Uneasy")
		expect(FearMath.tier(65, CONFIG)).toBe("Scared")
		expect(FearMath.tier(95, CONFIG)).toBe("Panicked")
	end)
end)

describe("FearMath.spike", function()
	it("scales with calmer scares and clamps", function()
		expect(FearMath.spike(10, 20, CONFIG, false)).toBe(30)
		expect(FearMath.spike(10, 20, CONFIG, true)).toBe(20)
		expect(FearMath.spike(95, 20, CONFIG, false)).toBe(100)
	end)
end)
