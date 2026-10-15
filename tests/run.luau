-- Test entry point: `lune run tests/run`
-- 1. Compiles every .luau file in src/ so syntax errors fail fast.
-- 2. Runs the unit specs for the pure game logic.

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local TestKit = require("./TestKit")

local syntaxErrors = {}
local checked = 0

local function walk(dir: string)
	for _, name in fs.readDir(dir) do
		local path = dir .. "/" .. name
		if fs.isDir(path) then
			walk(path)
		elseif string.sub(name, -5) == ".luau" then
			checked += 1
			local ok, err = pcall(luau.compile, fs.readFile(path))
			if not ok then
				table.insert(syntaxErrors, path .. ": " .. tostring(err))
			end
		end
	end
end
walk("src")

require("./specs/FearMath.spec")
require("./specs/Progression.spec")
require("./specs/QuestLogic.spec")
require("./specs/TableUtil.spec")
require("./specs/PuzzleCode.spec")
require("./specs/RateLimit.spec")
require("./specs/Signal.spec")
require("./specs/Hearing.spec")
require("./specs/ChapterUnlock.spec")
require("./specs/Trust.spec")
require("./specs/Gaze.spec")
require("./specs/Gait.spec")
require("./specs/BestTimes.spec")

local results = TestKit.results()
print(string.format("Syntax: %d files compiled, %d errors", checked, #syntaxErrors))
for _, message in syntaxErrors do
	print("  " .. message)
end
print(string.format("Specs: %d passed, %d failed", results.passed, results.failed))
for _, message in results.failures do
	print("  FAIL " .. message)
end

if #syntaxErrors > 0 or results.failed > 0 then
	process.exit(1)
end
