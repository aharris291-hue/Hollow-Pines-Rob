-- Generates the ranger radio frequency puzzle. Each server gets its own code,
-- split across clue notes so the team has to search the station together.

local PuzzleCode = {}

function PuzzleCode.generate(seed: number, digits: number)
	local state = (seed % 2147483646) + 1
	local function nextDigit(): number
		state = (state * 48271) % 2147483647
		return state % 10
	end

	local code = {}
	local clues = {}
	local symbols = { "Pine", "Moon", "Owl", "Lantern", "Bridge", "Raven" }
	for i = 1, digits do
		local digit = nextDigit()
		table.insert(code, tostring(digit))
		table.insert(clues, { order = i, symbol = symbols[(i - 1) % #symbols + 1], digit = digit })
	end
	return table.concat(code), clues
end

function PuzzleCode.check(expected: string, attempt: string): boolean
	if type(attempt) ~= "string" then
		return false
	end
	local cleaned = string.gsub(attempt, "%D", "")
	return cleaned == expected
end

return PuzzleCode
