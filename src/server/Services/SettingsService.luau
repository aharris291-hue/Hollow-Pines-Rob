-- Accessibility and audio settings, saved with the profile.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local DataTemplate = require(Shared.Config.DataTemplate)
local Net = require(Shared.Util.Net)

local SettingsService = {}

local services

local RANGES = {
	TextScale = { 1, 1.5 },
	MusicVolume = { 0, 1 },
	EffectsVolume = { 0, 1 },
}

function SettingsService:Init(registry)
	services = registry

	Net.Event("ChangeSetting").OnServerEvent:Connect(function(player, key, value)
		local default = DataTemplate.Settings[key]
		if default == nil or type(value) ~= type(default) then
			return
		end
		if type(value) == "number" then
			if value ~= value then
				return -- NaN
			end
			local range = RANGES[key]
			value = math.clamp(value, range[1], range[2])
		end
		services.DataService:Update(player, function(data)
			data.Settings[key] = value
		end)
	end)
end

function SettingsService:Get(player: Player, key: string)
	local data = services.DataService:Get(player)
	if data then
		return data.Settings[key]
	end
	return DataTemplate.Settings[key]
end

return SettingsService
