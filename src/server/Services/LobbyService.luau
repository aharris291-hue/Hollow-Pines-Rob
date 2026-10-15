-- Builds the greybox lobby camp if the place has no hand-built "Lobby" model.

local Lighting = game:GetService("Lighting")

local World = script.Parent.Parent:WaitForChild("World")
local Builder = require(World.Builder)

local LobbyService = {}

local function buildLobby()
	local map = Instance.new("Model")
	map.Name = "Lobby"

	Builder.part(map, "Ground", Vector3.new(220, 2, 220), CFrame.new(0, -1, 0), Color3.fromRGB(58, 74, 48), Enum.Material.Grass)

	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "LobbySpawn"
	spawnLocation.Size = Vector3.new(10, 1, 10)
	spawnLocation.CFrame = CFrame.new(0, 0.5, 18)
	spawnLocation.Anchored = true
	spawnLocation.Transparency = 1
	spawnLocation.CanCollide = false
	spawnLocation.Neutral = true
	spawnLocation.Duration = 0
	spawnLocation.Parent = map

	-- Campfire: the warm, safe heart of the lobby.
	Builder.part(map, "FirePit", Vector3.new(6, 1, 6), CFrame.new(0, 0.5, 0), Color3.fromRGB(70, 70, 70), Enum.Material.Slate)
	local fire = Builder.part(map, "Fire", Vector3.new(2, 2, 2), CFrame.new(0, 2, 0), Color3.fromRGB(255, 140, 50), Enum.Material.Neon)
	fire.CanCollide = false
	local fireLight = Instance.new("PointLight")
	fireLight.Color = Color3.fromRGB(255, 160, 80)
	fireLight.Range = 40
	fireLight.Brightness = 2
	fireLight.Parent = fire
	Instance.new("Fire", fire)

	for i = 0, 5 do
		local angle = i / 6 * math.pi * 2
		local log = Builder.part(map, "LogSeat", Vector3.new(5, 1.5, 1.5), CFrame.new(math.cos(angle) * 9, 0.75, math.sin(angle) * 9) * CFrame.Angles(0, -angle + math.pi / 2, 0), Color3.fromRGB(92, 64, 44), Enum.Material.Wood)
		log.Shape = Enum.PartType.Cylinder
	end

	-- Trailhead arch players walk towards; the queue itself uses the Play button.
	Builder.part(map, "TrailPostL", Vector3.new(1.5, 14, 1.5), CFrame.new(-8, 7, -40), Color3.fromRGB(92, 64, 44), Enum.Material.Wood)
	Builder.part(map, "TrailPostR", Vector3.new(1.5, 14, 1.5), CFrame.new(8, 7, -40), Color3.fromRGB(92, 64, 44), Enum.Material.Wood)
	local sign = Builder.part(map, "TrailSign", Vector3.new(18, 3, 1), CFrame.new(0, 13, -40), Color3.fromRGB(120, 86, 56), Enum.Material.Wood)
	Builder.label(sign, "HOLLOW PINES TRAIL", Enum.NormalId.Back)
	Builder.label(sign, "HOLLOW PINES TRAIL", Enum.NormalId.Front)

	Builder.forest(map, { seed = 7, count = 180, center = Vector3.zero, innerRadius = 70, outerRadius = 105 })

	map.Parent = workspace
end

function LobbyService:Start()
	if not workspace:FindFirstChild("Lobby") then
		buildLobby()
	end
	Lighting.ClockTime = 19.6
	Lighting.Brightness = 1.5
	Lighting.Ambient = Color3.fromRGB(70, 60, 80)
	Lighting.OutdoorAmbient = Color3.fromRGB(90, 80, 100)
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
	atmosphere.Density = 0.3
	atmosphere.Color = Color3.fromRGB(150, 120, 140)
	atmosphere.Decay = Color3.fromRGB(90, 70, 100)
end

return LobbyService
