-- Server entry point. Picks which services run for this place, then calls
-- Init on all of them (no yielding, no cross-service calls) and Start after.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared.Config.GameConfig)
local Net = require(Shared.Util.Net)

Net.Setup()

-- Clients set these groups' volumes locally from their saved settings.
for _, groupName in { "Music", "Effects" } do
	if not SoundService:FindFirstChild(groupName) then
		local group = Instance.new("SoundGroup")
		group.Name = groupName
		group.Parent = SoundService
	end
end

local function resolveRole(): string
	if GameConfig.Places.Lobby ~= 0 and game.PlaceId == GameConfig.Places.Lobby then
		return "Lobby"
	end
	for key, placeId in GameConfig.Places do
		if key ~= "Lobby" and placeId ~= 0 and game.PlaceId == placeId then
			return key -- "Chapter1", "Chapter2", ...
		end
	end
	-- Unpublished or Studio: the Rojo project decides (default.project.json = Solo).
	return ReplicatedStorage:GetAttribute("PlaceRole") or "Solo"
end

local role = resolveRole()
ReplicatedStorage:SetAttribute("PlaceRole", role)

local COMMON = {
	"DataService",
	"EconomyService",
	"ProgressionService",
	"InventoryService",
	"MonetizationService",
	"QuestService",
	"AchievementService",
	"SettingsService",
	"PetService",
}

local BY_ROLE = {
	Lobby = { "LobbyService", "MatchmakingService" },
	-- Every chapter place (and Solo) runs the same gameplay services.
	Chapter = { "PlayerStateService", "EquipmentService", "NoiseService", "TrustService", "FearService", "CreatureService", "OnboardingService", "ChapterService" },
}

local servicesFolder = script:WaitForChild("Services")
local services = {}
local order = {}

for _, name in COMMON do
	table.insert(order, name)
end
for _, name in BY_ROLE[if role == "Lobby" then "Lobby" else "Chapter"] do
	table.insert(order, name)
end

for _, name in order do
	services[name] = require(servicesFolder:WaitForChild(name))
end

for _, name in order do
	local service = services[name]
	if service.Init then
		service:Init(services)
	end
end

for _, name in order do
	local service = services[name]
	if service.Start then
		task.spawn(service.Start, service)
	end
end

print(string.format("[HollowPines] v%s server started as %s with %d services", GameConfig.Version, role, #order))
