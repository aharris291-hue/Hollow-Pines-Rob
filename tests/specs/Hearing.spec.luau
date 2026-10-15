local TestKit = require("../TestKit")
local Hearing = require("../../src/shared/Util/Hearing")
local describe, it, expect = TestKit.describe, TestKit.it, TestKit.expect

-- Lune has no Vector3 global; a tiny stand-in with what Hearing uses.
local Vec = {}
Vec.__index = Vec
Vec.__sub = function(a, b)
	return setmetatable({ x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }, Vec)
end
Vec.__index = function(self, key)
	if key == "Magnitude" then
		return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
	end
	return rawget(Vec, key)
end
local function v(x, z)
	return setmetatable({ x = x, y = 0, z = z }, Vec)
end

describe("Hearing", function()
	it("ignores noises outside their radius", function()
		local noise = { position = v(100, 0), radius = 40, time = 0 }
		expect(Hearing.intensity(v(0, 0), noise, 0, 4)).toBe(0)
	end)

	it("hears closer noises louder", function()
		local near = { position = v(5, 0), radius = 40, time = 0 }
		local far = { position = v(30, 0), radius = 40, time = 0 }
		expect(Hearing.intensity(v(0, 0), near, 0, 4)).toBeGreaterThan(Hearing.intensity(v(0, 0), far, 0, 4))
	end)

	it("forgets noises older than its memory", function()
		local noise = { position = v(1, 0), radius = 40, time = 0 }
		expect(Hearing.intensity(v(0, 0), noise, 5, 4)).toBe(0)
	end)

	it("picks the loudest noise", function()
		local quiet = { position = v(35, 0), radius = 40, time = 0 }
		local loud = { position = v(10, 0), radius = 90, time = 0 }
		local best = Hearing.loudest(v(0, 0), { quiet, loud }, 0, 4)
		expect(best).toBe(loud)
	end)

	it("scales hearing with a multiplier", function()
		local noise = { position = v(50, 0), radius = 40, time = 0 }
		expect(Hearing.intensity(v(0, 0), noise, 0, 4, 1)).toBe(0)
		expect(Hearing.intensity(v(0, 0), noise, 0, 4, 1.5)).toBeGreaterThan(0)
	end)

	it("prunes old noises in place", function()
		local noises = { { time = 0 }, { time = 9 }, { time = 10 } }
		Hearing.prune(noises, 10, 4)
		expect(#noises).toBe(2)
	end)
end)
