-- The Ranger: the missing ranger of Station 7, heard on the radio in Chapter 1.
-- Becomes a patrolling, sound-hunting creature from Chapter 2 (docs/ROADMAP.md).
-- Kept as a stub so CreatureService already knows the full roster.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Creatures = require(Shared.Config.Creatures)

local Ranger = {}
Ranger.__index = Ranger

function Ranger.new()
	return setmetatable({ config = Creatures.Ranger }, Ranger)
end

function Ranger:Update(_dt: number) end

function Ranger:Destroy() end

return Ranger
