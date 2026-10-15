-- Builds the Chapter 1 greybox: the crashed bus, the footprint trail, the ranger
-- station and its clearing, the old service road and the bridge out.
-- Returns references the chapter script needs. A level designer can swap this
-- for a hand-built map as long as the same references are provided.

local Builder = require(script.Parent.Builder)

local Chapter1Map = {}

local YELLOW = Color3.fromRGB(235, 180, 40)
local DARK = Color3.fromRGB(30, 30, 34)
local WOOD = Color3.fromRGB(96, 70, 48)
local DIRT = Color3.fromRGB(78, 62, 46)

local STATION = Vector3.new(-110, 0, -60)
local BUS = CFrame.new(14, 0, -260) * CFrame.Angles(0, math.rad(12), 0)
local RIVER_Z = { 200, 240 }
local EXIT = Vector3.new(0, 0, 300)

local function path(map: Instance, points: { Vector3 }, width: number, name: string)
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local length = (b - a).Magnitude
		local mid = (a + b) / 2
		local strip = Builder.part(map, name, Vector3.new(width, 0.1, length + width * 0.5), CFrame.lookAt(mid + Vector3.new(0, 0.05, 0), b + Vector3.new(0, 0.05, 0)), DIRT, Enum.Material.Ground)
		strip.CanCollide = false
		strip.CastShadow = false
	end
end

local function footprints(map: Instance, points: { Vector3 })
	local folder = Instance.new("Folder")
	folder.Name = "Footprints"
	local left = true
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local direction = (b - a).Unit
		local side = Vector3.new(-direction.Z, 0, direction.X)
		local distance = 0
		while distance < (b - a).Magnitude do
			local position = a + direction * distance + side * (if left then 0.6 else -0.6) + Vector3.new(0, 0.13, 0)
			local step = Builder.part(folder, "Footprint", Vector3.new(0.7, 0.05, 1.3), CFrame.lookAt(position, position + direction), Color3.fromRGB(40, 30, 24), Enum.Material.Mud)
			step.CanCollide = false
			step.CanQuery = false
			step.CastShadow = false
			left = not left
			distance += 2.2
		end
	end
	folder.Parent = map
end

local function buildBus(map: Instance, refs)
	local bus = Instance.new("Model")
	bus.Name = "Bus"
	local function at(x, y, z)
		return BUS * CFrame.new(x, y, z)
	end

	Builder.part(bus, "Floor", Vector3.new(10, 1, 36), at(0, 1, 0), DARK, Enum.Material.DiamondPlate)
	Builder.part(bus, "Roof", Vector3.new(10.4, 1, 36.4), at(0, 9.5, 0), YELLOW, Enum.Material.Metal)

	-- Left side: lower panel + windows + top rail.
	Builder.part(bus, "LeftPanel", Vector3.new(0.6, 3.5, 36), at(-5, 3.25, 0), YELLOW, Enum.Material.Metal)
	local leftGlass = Builder.part(bus, "LeftWindows", Vector3.new(0.3, 3.5, 36), at(-5, 6.75, 0), Color3.fromRGB(40, 50, 60), Enum.Material.Glass)
	leftGlass.Transparency = 0.6
	Builder.part(bus, "LeftRail", Vector3.new(0.6, 0.6, 36), at(-5, 8.8, 0), YELLOW, Enum.Material.Metal)

	-- Right side with the door gap near the front (local z -16 to -12).
	Builder.part(bus, "RightPanelFront", Vector3.new(0.6, 7.6, 2), at(5, 5, -17), YELLOW, Enum.Material.Metal)
	Builder.part(bus, "RightPanel", Vector3.new(0.6, 3.5, 30), at(5, 3.25, 3), YELLOW, Enum.Material.Metal)
	local rightGlass = Builder.part(bus, "RightWindows", Vector3.new(0.3, 3.5, 30), at(5, 6.75, 3), Color3.fromRGB(40, 50, 60), Enum.Material.Glass)
	rightGlass.Transparency = 0.6
	Builder.part(bus, "RightRail", Vector3.new(0.6, 0.6, 30), at(5, 8.8, 3), YELLOW, Enum.Material.Metal)
	Builder.part(bus, "DoorTop", Vector3.new(0.6, 1.2, 4), at(5, 8.4, -14), YELLOW, Enum.Material.Metal)
	local label = Builder.part(bus, "SchoolName", Vector3.new(0.2, 1.4, 20), at(5.35, 3.6, 3), YELLOW, Enum.Material.Metal)
	Builder.label(label, "HOLLOW PINES MIDDLE SCHOOL", Enum.NormalId.Right, Color3.fromRGB(20, 20, 20))

	local windshield = Builder.part(bus, "Windshield", Vector3.new(10, 4, 0.3), at(0, 6.5, -18), Color3.fromRGB(70, 80, 90), Enum.Material.Glass)
	windshield.Transparency = 0.45
	Builder.part(bus, "FrontPanel", Vector3.new(10, 4, 0.6), at(0, 3, -18), YELLOW, Enum.Material.Metal)
	Builder.part(bus, "RearWall", Vector3.new(10, 8, 0.6), at(0, 5.5, 18), YELLOW, Enum.Material.Metal)
	Builder.part(bus, "Hood", Vector3.new(9, 4.5, 6), at(0, 2.75, -21), YELLOW, Enum.Material.Metal)

	-- Headlights stabbing into the trees; one is smashed.
	local lamp = Builder.part(bus, "Headlight", Vector3.new(1.2, 1.2, 0.4), at(3, 3.5, -24.1), Color3.fromRGB(255, 250, 220), Enum.Material.Neon)
	local beam = Instance.new("SpotLight")
	beam.Face = Enum.NormalId.Front
	beam.Range = 60
	beam.Angle = 50
	beam.Brightness = 3
	beam.Parent = lamp
	Builder.part(bus, "HeadlightBroken", Vector3.new(1.2, 1.2, 0.4), at(-3, 3.5, -24.1), DARK, Enum.Material.Glass)

	for z = -9, 15, 4 do
		for _, x in { -3, 3 } do
			Builder.part(bus, "Seat", Vector3.new(3.2, 1.2, 1.6), at(x, 2.1, z), Color3.fromRGB(120, 40, 36), Enum.Material.Fabric)
			Builder.part(bus, "SeatBack", Vector3.new(3.2, 2.4, 0.5), at(x, 3.3, z + 0.9), Color3.fromRGB(120, 40, 36), Enum.Material.Fabric)
		end
	end

	local driverSeat = Builder.part(bus, "DriverSeat", Vector3.new(2.4, 1.2, 2), at(-3, 2.1, -15), Color3.fromRGB(60, 60, 64), Enum.Material.Fabric)
	Builder.part(bus, "Wheel", Vector3.new(1.8, 1.8, 0.3), at(-3, 4.4, -16.8) * CFrame.Angles(math.rad(-30), 0, 0), DARK, Enum.Material.Rubber)
	refs.DriverSeat = driverSeat

	local crate = Builder.part(bus, "EmergencyKit", Vector3.new(3, 2, 2), at(0, 2.5, 15.5), Color3.fromRGB(170, 40, 40), Enum.Material.Metal)
	Builder.label(crate, "EMERGENCY", Enum.NormalId.Front)
	refs.KitCrate = crate

	local busNote = Builder.part(bus, "ItineraryNote", Vector3.new(1.4, 0.05, 1.8), at(3, 2.75, -9), Color3.fromRGB(235, 230, 210), Enum.Material.Paper)
	refs.BusNote = busNote

	local cabinLamp = Builder.part(bus, "CabinLamp", Vector3.new(1, 0.3, 3), at(0, 8.9, 0), Color3.fromRGB(255, 220, 150), Enum.Material.Neon)
	local cabinLight = Instance.new("PointLight")
	cabinLight.Range = 14
	cabinLight.Brightness = 0.8
	cabinLight.Color = Color3.fromRGB(255, 210, 150)
	cabinLight.Parent = cabinLamp
	refs.BusLight = cabinLight

	refs.BusSpawns = {}
	for z = -8, 12, 5 do
		table.insert(refs.BusSpawns, at(0, 4, z) * CFrame.Angles(0, math.pi, 0))
	end
	refs.BusDoor = (at(8, 0, -14)).Position

	-- The tree the bus hit.
	local rng = Random.new(1)
	Builder.tree(map, (at(0, 0, -27)).Position, 38, rng)

	bus.Parent = map
end

local function buildStation(map: Instance, refs)
	local station = Instance.new("Model")
	station.Name = "RangerStation"
	local function at(x, y, z)
		return CFrame.new(STATION + Vector3.new(x, y, z))
	end
	local wallColor = Color3.fromRGB(110, 84, 60)

	Builder.part(station, "Floor", Vector3.new(36, 1, 26), at(0, 0.5, 0), Color3.fromRGB(82, 62, 46), Enum.Material.WoodPlanks)
	Builder.part(station, "Roof", Vector3.new(39, 1, 29), at(0, 12.5, 0), Color3.fromRGB(56, 44, 40), Enum.Material.Slate)
	Builder.part(station, "WestWall", Vector3.new(1, 12, 26), at(-17.5, 6.5, 0), wallColor, Enum.Material.WoodPlanks)
	Builder.part(station, "NorthWall", Vector3.new(36, 12, 1), at(0, 6.5, -12.5), wallColor, Enum.Material.WoodPlanks)
	Builder.part(station, "SouthWall", Vector3.new(36, 12, 1), at(0, 6.5, 12.5), wallColor, Enum.Material.WoodPlanks)
	-- East wall faces the trail, with a doorway in the middle.
	Builder.part(station, "EastWallN", Vector3.new(1, 12, 10), at(17.5, 6.5, -8), wallColor, Enum.Material.WoodPlanks)
	Builder.part(station, "EastWallS", Vector3.new(1, 12, 10), at(17.5, 6.5, 8), wallColor, Enum.Material.WoodPlanks)
	Builder.part(station, "EastWallTop", Vector3.new(1, 4, 6), at(17.5, 10.5, 0), wallColor, Enum.Material.WoodPlanks)
	local sign = Builder.part(station, "Sign", Vector3.new(0.4, 2.5, 12), at(18.3, 13.5, 0), Color3.fromRGB(70, 90, 60), Enum.Material.Wood)
	Builder.label(sign, "RANGER STATION 7", Enum.NormalId.Right)

	refs.StationLights = {}
	for _, x in { -10, 0, 10 } do
		local fixture = Builder.part(station, "CeilingLamp", Vector3.new(2, 0.4, 2), at(x, 11.8, 0), Color3.fromRGB(60, 60, 60), Enum.Material.Metal)
		local light = Instance.new("PointLight")
		light.Range = 22
		light.Brightness = 1.4
		light.Color = Color3.fromRGB(255, 226, 170)
		light.Enabled = false
		light.Parent = fixture
		table.insert(refs.StationLights, { part = fixture, light = light })
	end
	local porch = Builder.part(station, "PorchLamp", Vector3.new(1, 1, 1), at(18.6, 9.5, 4), Color3.fromRGB(60, 60, 60), Enum.Material.Metal)
	local porchLight = Instance.new("PointLight")
	porchLight.Range = 26
	porchLight.Brightness = 1.6
	porchLight.Color = Color3.fromRGB(255, 200, 140)
	porchLight.Enabled = false
	porchLight.Parent = porch
	table.insert(refs.StationLights, { part = porch, light = porchLight })

	refs.FuseBox = Builder.part(station, "FuseBox", Vector3.new(1, 4, 3), at(-16.6, 5, 7), Color3.fromRGB(90, 96, 100), Enum.Material.Metal)

	Builder.part(station, "RadioDesk", Vector3.new(6, 3, 3), at(-12, 2.5, -10), WOOD, Enum.Material.Wood)
	refs.Radio = Builder.part(station, "Radio", Vector3.new(2.4, 1.4, 1.4), at(-12, 4.7, -10), Color3.fromRGB(50, 54, 50), Enum.Material.Metal)

	refs.MapTable = Builder.part(station, "MapTable", Vector3.new(8, 0.5, 5), at(0, 3, 2), WOOD, Enum.Material.Wood)
	for _, offset in { Vector3.new(-3.5, 0, -2), Vector3.new(3.5, 0, -2), Vector3.new(-3.5, 0, 2), Vector3.new(3.5, 0, 2) } do
		Builder.part(station, "TableLeg", Vector3.new(0.5, 2.5, 0.5), at(offset.X, 1.5 + 0.25, 2 + offset.Z), WOOD, Enum.Material.Wood)
	end
	local trailMap = Builder.part(station, "TrailMap", Vector3.new(6, 0.06, 3.6), at(0, 3.28, 2), Color3.fromRGB(220, 205, 170), Enum.Material.Paper)
	Builder.label(trailMap, "OLD SERVICE ROAD ➜ BRIDGE ➜ ROUTE 9", Enum.NormalId.Top, Color3.fromRGB(70, 40, 30))

	-- Clue notes for the radio puzzle, one per wall so the team has to split up.
	refs.ClueNotes = {
		Builder.part(station, "ClueNote", Vector3.new(2, 2.6, 0.1), at(-6, 6, -11.9), Color3.fromRGB(235, 228, 205), Enum.Material.Paper),
		Builder.part(station, "ClueNote", Vector3.new(2, 2.6, 0.1), at(8, 6, 11.9), Color3.fromRGB(235, 228, 205), Enum.Material.Paper),
		Builder.part(station, "ClueNote", Vector3.new(0.1, 2.6, 2), at(16.9, 6, -6), Color3.fromRGB(235, 228, 205), Enum.Material.Paper),
	}
	refs.RangerLog = Builder.part(station, "RangerLog", Vector3.new(1.6, 0.2, 1.2), at(-9.5, 4.1, -10), Color3.fromRGB(90, 60, 40), Enum.Material.Leather)

	refs.SafeZone = { cframe = at(0, 6.5, 0), size = Vector3.new(34, 12, 24) }
	refs.StationDoor = (at(22, 0, 0)).Position
	refs.StationCheckpoint = at(4, 3.5, 6)

	station.Parent = map
end

local function buildFuseSpots(map: Instance, refs)
	local props = Instance.new("Folder")
	props.Name = "ClearingProps"
	local spots = {
		{ name = "PicnicTable", offset = Vector3.new(30, 0, 25), size = Vector3.new(6, 2.5, 3), color = WOOD },
		{ name = "Woodpile", offset = Vector3.new(-35, 0, 30), size = Vector3.new(5, 3, 3), color = Color3.fromRGB(110, 76, 50) },
		{ name = "Outhouse", offset = Vector3.new(-40, 0, -30), size = Vector3.new(4, 8, 4), color = Color3.fromRGB(80, 100, 70) },
		{ name = "OldTruck", offset = Vector3.new(25, 0, -38), size = Vector3.new(7, 4.5, 12), color = Color3.fromRGB(70, 90, 110) },
		{ name = "TowerBase", offset = Vector3.new(0, 0, 48), size = Vector3.new(5, 10, 5), color = Color3.fromRGB(80, 66, 54) },
		{ name = "Shed", offset = Vector3.new(45, 0, 2), size = Vector3.new(7, 6, 6), color = Color3.fromRGB(100, 70, 60) },
	}
	refs.FuseSpots = {}
	for _, spot in spots do
		local base = STATION + spot.offset
		Builder.part(props, spot.name, spot.size, CFrame.new(base + Vector3.new(0, spot.size.Y / 2, 0)), spot.color, Enum.Material.Wood)
		-- Fuses sit on the ground beside the prop, never on top, so short avatars reach them.
		local side = Vector3.new(spot.size.X / 2 + 1.5, 0.6, 0)
		table.insert(refs.FuseSpots, CFrame.new(base + side))
	end
	props.Parent = map
end

local function buildRoadAndBridge(map: Instance, refs)
	local asphalt = Color3.fromRGB(46, 46, 50)
	local south = Builder.part(map, "Road", Vector3.new(22, 0.2, RIVER_Z[1] - 5 + 400), CFrame.new(0, 0.1, (-400 + RIVER_Z[1] - 5) / 2), asphalt, Enum.Material.Asphalt)
	south.CastShadow = false
	local north = Builder.part(map, "Road", Vector3.new(22, 0.2, 110), CFrame.new(0, 0.1, RIVER_Z[2] + 55), asphalt, Enum.Material.Asphalt)
	north.CastShadow = false

	local riverWidth = RIVER_Z[2] - RIVER_Z[1]
	local river = Builder.part(map, "River", Vector3.new(900, 1, riverWidth), CFrame.new(0, -0.4, (RIVER_Z[1] + RIVER_Z[2]) / 2), Color3.fromRGB(30, 50, 66), Enum.Material.Glass)
	river.Transparency = 0.2
	river.Reflectance = 0.2

	Builder.part(map, "Bridge", Vector3.new(14, 1, riverWidth + 8), CFrame.new(0, 0.6, (RIVER_Z[1] + RIVER_Z[2]) / 2), WOOD, Enum.Material.WoodPlanks)
	for _, x in { -7, 7 } do
		Builder.part(map, "Railing", Vector3.new(0.6, 3, riverWidth + 8), CFrame.new(x, 2.5, (RIVER_Z[1] + RIVER_Z[2]) / 2), WOOD, Enum.Material.Wood)
	end
	-- The river can only be crossed on the bridge.
	for _, z in RIVER_Z do
		Builder.invisibleWall(map, Vector3.new(443, 40, 1), CFrame.new(-228.5, 20, z))
		Builder.invisibleWall(map, Vector3.new(443, 40, 1), CFrame.new(228.5, 20, z))
	end

	-- The exit: a rescue truck's headlights waiting on Route 9.
	Builder.part(map, "GatePostL", Vector3.new(1.5, 10, 1.5), CFrame.new(-12, 5, EXIT.Z - 12), WOOD, Enum.Material.Wood)
	Builder.part(map, "GatePostR", Vector3.new(1.5, 10, 1.5), CFrame.new(12, 5, EXIT.Z - 12), WOOD, Enum.Material.Wood)
	local gateSign = Builder.part(map, "GateSign", Vector3.new(26, 3, 0.6), CFrame.new(0, 10, EXIT.Z - 12), Color3.fromRGB(40, 80, 50), Enum.Material.Wood)
	Builder.label(gateSign, "ROUTE 9", Enum.NormalId.Front)
	Builder.label(gateSign, "ROUTE 9", Enum.NormalId.Back)
	local truck = Builder.part(map, "RescueTruck", Vector3.new(8, 6, 16), CFrame.new(0, 3, EXIT.Z + 20), Color3.fromRGB(200, 200, 205), Enum.Material.Metal)
	local truckLight = Instance.new("SpotLight")
	truckLight.Face = Enum.NormalId.Front
	truckLight.Range = 60
	truckLight.Angle = 70
	truckLight.Brightness = 4
	truckLight.Color = Color3.fromRGB(255, 245, 225)
	truckLight.Parent = truck

	refs.BridgePosition = Vector3.new(0, 0, (RIVER_Z[1] + RIVER_Z[2]) / 2)
	refs.ExitZone = { cframe = CFrame.new(EXIT + Vector3.new(0, 5, 0)), size = Vector3.new(40, 14, 24) }
	refs.ExitHold = CFrame.new(EXIT + Vector3.new(0, 4, 2)) -- in front of the truck
end

local function buildBounds(map: Instance)
	Builder.invisibleWall(map, Vector3.new(2, 80, 800), CFrame.new(-440, 40, -40))
	Builder.invisibleWall(map, Vector3.new(2, 80, 800), CFrame.new(440, 40, -40))
	Builder.invisibleWall(map, Vector3.new(880, 80, 2), CFrame.new(0, 40, -430))
	Builder.invisibleWall(map, Vector3.new(880, 80, 2), CFrame.new(0, 40, 350))
end

function Chapter1Map.Build()
	local refs = {}
	local map = Instance.new("Model")
	map.Name = "Chapter1"
	refs.Map = map

	Builder.part(map, "Ground", Vector3.new(900, 2, 800), CFrame.new(0, -1, -40), Color3.fromRGB(44, 58, 40), Enum.Material.Grass)

	buildBus(map, refs)
	buildStation(map, refs)
	buildFuseSpots(map, refs)
	buildRoadAndBridge(map, refs)
	buildBounds(map)

	refs.TrailPoints = {
		refs.BusDoor,
		Vector3.new(-10, 0, -235),
		Vector3.new(-40, 0, -190),
		Vector3.new(-70, 0, -140),
		Vector3.new(-95, 0, -100),
		refs.StationDoor,
	}
	path(map, refs.TrailPoints, 5, "Trail")
	footprints(map, refs.TrailPoints)
	refs.TrailMidpoint = Vector3.new(-55, 0, -165)
	refs.WatcherReveal = CFrame.lookAt(Vector3.new(-100, 0, -192), Vector3.new(-55, 0, -165))

	refs.ServiceRoad = {
		refs.StationDoor,
		Vector3.new(-60, 0, -30),
		Vector3.new(-20, 0, 10),
		Vector3.new(0, 0, 40),
	}
	path(map, refs.ServiceRoad, 8, "ServiceRoad")
	refs.ChaseCheckpoint = CFrame.new(refs.StationDoor + Vector3.new(4, 3, 0))
	refs.ChaseTrigger = Vector3.new(-60, 0, -30)

	local busPosition = BUS.Position
	local function avoid(p: Vector3): boolean
		if math.abs(p.X) < 16 then
			return true -- road
		end
		if p.Z > RIVER_Z[1] - 6 and p.Z < RIVER_Z[2] + 6 then
			return true
		end
		if (p - busPosition).Magnitude < 32 or (p - STATION).Magnitude < 60 or (p - EXIT).Magnitude < 40 then
			return true
		end
		for i = 1, #refs.TrailPoints - 1 do
			if Builder.distanceToSegment(p, refs.TrailPoints[i], refs.TrailPoints[i + 1]) < 7 then
				return true
			end
		end
		for i = 1, #refs.ServiceRoad - 1 do
			if Builder.distanceToSegment(p, refs.ServiceRoad[i], refs.ServiceRoad[i + 1]) < 9 then
				return true
			end
		end
		return false
	end
	Builder.forest(map, { seed = 1993, count = 650, center = Vector3.new(0, 0, -40), halfSize = Vector2.new(425, 385), avoid = avoid })

	map.Parent = workspace
	return refs
end

return Chapter1Map
