-- XP and levels. Levels unlock equipment (Items.Equipment[*].unlockLevel).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Progression = require(Shared.Util.Progression)
local Items = require(Shared.Config.Items)
local Net = require(Shared.Util.Net)
local EventBus = require(script.Parent.Parent.EventBus)

local ProgressionService = {}

local services

local function unlockForLevel(data, level: number): { string }
	local unlocked = {}
	for id, item in Items.Equipment do
		if item.unlockLevel <= level and not data.Owned[id] then
			data.Owned[id] = true
			table.insert(unlocked, item.name)
		end
	end
	return unlocked
end

function ProgressionService:Init(registry)
	services = registry
end

function ProgressionService:Start()
	-- Catch up profiles created before an unlock level was lowered.
	services.DataService.ProfileLoaded:Connect(function(player, data)
		unlockForLevel(data, data.Level)
	end)
end

function ProgressionService:AddXP(player: Player, amount: number)
	local gainedLevels, newLevel, unlocked = 0, 1, {}
	local ok = services.DataService:Update(player, function(data)
		local level, xp, gained = Progression.addXP(data.Level, data.XP, amount)
		data.Level, data.XP = level, xp
		data.Stats.Level = level
		gainedLevels, newLevel = gained, level
		if gained > 0 then
			unlocked = unlockForLevel(data, level)
		end
	end)
	if not ok or gainedLevels == 0 then
		return
	end

	player:SetAttribute("Level", newLevel)
	for level = newLevel - gainedLevels + 1, newLevel do
		services.EconomyService:Add(player, Progression.levelReward(level), "LevelReward", true)
	end
	local message = "Level " .. newLevel .. "!"
	if #unlocked > 0 then
		message ..= " Unlocked: " .. table.concat(unlocked, ", ")
	end
	Net.Event("Toast"):FireClient(player, message, "LevelUp")
	EventBus.Fire("LevelUp", player, newLevel)
end

return ProgressionService
