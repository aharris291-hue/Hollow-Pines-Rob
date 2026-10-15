-- A very small test framework so the pure game logic can run under Lune.

local TestKit = {}

local results = { passed = 0, failed = 0, failures = {} }
local currentSuite = ""

function TestKit.describe(name: string, body: () -> ())
	currentSuite = name
	body()
end

function TestKit.it(name: string, body: () -> ())
	local ok, err = pcall(body)
	if ok then
		results.passed += 1
	else
		results.failed += 1
		table.insert(results.failures, string.format("%s > %s\n    %s", currentSuite, name, tostring(err)))
	end
end

local function fail(message: string)
	error(message, 3)
end

function TestKit.expect(actual)
	return {
		toBe = function(expected)
			if actual ~= expected then
				fail(string.format("expected %s, got %s", tostring(expected), tostring(actual)))
			end
		end,
		toBeNear = function(expected, epsilon)
			if math.abs(actual - expected) > (epsilon or 1e-6) then
				fail(string.format("expected ~%s, got %s", tostring(expected), tostring(actual)))
			end
		end,
		toBeGreaterThan = function(expected)
			if not (actual > expected) then
				fail(string.format("expected > %s, got %s", tostring(expected), tostring(actual)))
			end
		end,
		toBeLessThan = function(expected)
			if not (actual < expected) then
				fail(string.format("expected < %s, got %s", tostring(expected), tostring(actual)))
			end
		end,
	}
end

function TestKit.results()
	return results
end

return TestKit
