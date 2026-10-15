local TestKit = require("../TestKit")
local RateLimit = require("../../src/shared/Util/RateLimit")
local describe, it, expect = TestKit.describe, TestKit.it, TestKit.expect

describe("RateLimit", function()
	it("blocks calls inside the cooldown per key", function()
		local now = 0
		local limiter = RateLimit.new(1, function()
			return now
		end)
		expect(limiter:Allow("a")).toBe(true)
		expect(limiter:Allow("a")).toBe(false)
		expect(limiter:Allow("b")).toBe(true)
		now = 1.5
		expect(limiter:Allow("a")).toBe(true)
	end)
end)
