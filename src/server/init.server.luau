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
	elseif GameConfig.Places.Chapter1 ~= 0 and game.PlaceId == GameConfig.Places.Chapter1 then
		return "Chapter1"
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
	Chapter1 = { "PlayerStateService", "EquipmentService", "FearService", "CreatureService", "ChapterService" },
}
BY_ROLE.Solo = BY_ROLE.Chapter1

local servicesFolder = script:WaitForChild("Services")
local services = {}
local order = {}

for _, name in COMMON do
	table.insert(order, name)
end
for _, name in BY_ROLE[role] do
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
