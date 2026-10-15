-- XP curve and level-up maths. Pure, unit tested in tests/Progression.spec.luau.

local Progression = {}

Progression.MaxLevel = 50

function Progression.xpToNext(level: number): number
	return math.floor(100 * level ^ 1.4)
end

-- Returns the new level, leftover XP towards the next level, and levels gained.
function Progression.addXP(level: number, xp: number, amount: number): (number, number, number)
	local gained = 0
	xp += math.max(amount, 0)
	while level < Progression.MaxLevel and xp >= Progression.xpToNext(level) do
		xp -= Progression.xpToNext(level)
		level += 1
		gained += 1
	end
	if level >= Progression.MaxLevel then
		level = Progression.MaxLevel
		xp = 0
	end
	return level, xp, gained
end

-- Embers granted on reaching `level`.
function Progression.levelReward(level: number): number
	if level % 5 == 0 then
		return 250
	end
	return 50
end

return Progression
