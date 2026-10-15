-- The Hollow One: the secret at the heart of the forest, introduced in Chapter 4.
-- Stub only; its design lives in docs/GAME_DESIGN.md.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Creatures = require(Shared.Config.Creatures)

local HollowOne = {}
HollowOne.__index = HollowOne

function HollowOne.new()
	return setmetatable({ config = Creatures.HollowOne }, HollowOne)
end

function HollowOne:Update(_dt: number) end

function HollowOne:Destroy() end

return HollowOne
