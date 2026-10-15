local TestKit = require("../TestKit")
local Signal = require("../../src/shared/Util/Signal")
local describe, it, expect = TestKit.describe, TestKit.it, TestKit.expect

describe("Signal", function()
	it("fires connected handlers with arguments", function()
		local signal = Signal.new()
		local total = 0
		signal:Connect(function(a, b)
			total += a + b
		end)
		signal:Fire(2, 3)
		expect(total).toBe(5)
	end)

	it("stops calling disconnected handlers", function()
		local signal = Signal.new()
		local calls = 0
		local connection = signal:Connect(function()
			calls += 1
		end)
		signal:Fire()
		connection.Disconnect()
		signal:Fire()
		expect(calls).toBe(1)
	end)

	it("runs Once handlers a single time", function()
		local signal = Signal.new()
		local calls = 0
		signal:Once(function()
			calls += 1
		end)
		signal:Fire()
		signal:Fire()
		expect(calls).toBe(1)
	end)
end)
