-- Builds the Chapter 2 greybox: the flooded Hollow Pines Campground. The empty
-- rescue truck at the gate, rows of tents (hiding spots), flood pools (noisy to
-- cross), the lit camp office (safe), the boathouse on the lake, the lookout
-- tower and the helicopter landing zone.

local Builder = require(script.Parent.Builder)

local Chapter2Map = {}

local WOOD = Color3.fromRGB(96, 70, 48)
local DIRT = Color3.fromRGB(78, 62, 46)
local WATER = Color3.fromRGB(40, 70, 95)

local ENTRANCE = Vector3.new(0, 0, -250)
local OFFICE = Vector3.new(-130, 0, -170)
local TOWER = Vector3.new(-140, 0, 90)
local BOATHOUSE = Vector3.new(90, 0, 112)
local HELIPAD = Vector3.new(175, 0, -20)
local LAKE_Z = 125 -- the lake shore runs east-west here
local CAMP_CENTER = Vector3.new(0, 0, -60)

local function region(cframe: CFrame, size: Vector3)
	return { cframe = cframe, size = size }
end

local function buildTents(map: Instance, refs)
	local folder = Instance.new("Folder")
	folder.Name = "Tents"
	refs.HideSpots = {}
	refs.TentSpots = {}
	local colors = { Color3.fromRGB(70, 110, 80), Color3.fromRGB(150, 90, 50), Color3.fromRGB(70, 90, 130), Color3.fromRGB(130, 60, 60) }
	local index = 0
	for _, x in { -90, -60, -32, 32, 60, 90 } do
		for _, z in { -150, -112, -74, -36, 2 } do
			index += 1
			-- Leave gaps so the camp has open lanes as well as cover.
			if index % 5 ~= 0 then
				local base = CFrame.new(x, 0, z) * CFrame.Angles(0, if index % 2 == 0 then 0 else math.pi / 2, 0)
				local color = colors[index % #colors + 1]
				Builder.part(folder, "TentFloor", Vector3.new(6, 0.2, 8), base * CFrame.new(0, 0.1, 0), Color3.fromRGB(50, 50, 46), Enum.Material.Fabric).CanCollide = false
				for _, side in { -1, 1 } do
					local panel = Builder.part(folder, "TentSide", Vector3.new(0.2, 5.6, 8), base * CFrame.new(side * 1.6, 2.3, 0) * CFrame.Angles(0, 0, math.rad(side * 33)), color, Enum.Material.Fabric)
					panel.CastShadow = true
				end
				-- Standing still inside a tent hides you from The Ranger.
				table.insert(refs.HideSpots, region(base * CFrame.new(0, 2.5, 0), Vector3.new(3.4, 5, 7)))
				table.insert(refs.TentSpots, (base * CFrame.new(0, 0.6, 2.5)).Position)
			end
		end
	end
	folder.Parent = map
end

local function buildPools(map: Instance, refs)
	refs.SplashZones = {}
	local pools = {
		{ Vector3.new(0, 0, -95), Vector3.new(20, 0, 46) },
		{ Vector3.new(-46, 0, -20), Vector3.new(34, 0, 22) },
		{ Vector3.new(48, 0, -130), Vector3.new(30, 0, 26) },
		{ Vector3.new(15, 0, 45), Vector3.new(40, 0, 30) },
		{ Vector3.new(75, 0, 80), Vector3.new(36, 0, 26) },
		{ Vector3.new(-100, 0, 30), Vector3.new(30, 0, 40) },
	}
	for _, pool in pools do
		local water = Builder.part(map, "FloodWater", Vector3.new(pool[2].X, 0.5, pool[2].Z), CFrame.new(pool[1] + Vector3.new(0, 0.25, 0)), WATER, Enum.Material.Glass)
		water.Transparency = 0.35
		water.Reflectance = 0.15
		water.CanCollide = false
		water.CanQuery = false
		water.CastShadow = false
		table.insert(refs.SplashZones, region(CFrame.new(pool[1] + Vector3.new(0, 3, 0)), Vector3.new(pool[2].X, 6, pool[2].Z)))
	end
end

local function buildEntrance(map: Instance, refs)
	Builder.part(map, "Road", Vector3.new(20, 0.2, 140), CFrame.new(0, 0.1, -280), Color3.fromRGB(46, 46, 50), Enum.Material.Asphalt).CastShadow = false
	local truck = Builder.part(map, "RescueTruck", Vector3.new(8, 6, 16), CFrame.new(ENTRANCE + Vector3.new(6, 3, -12)), Color3.fromRGB(200, 200, 205), Enum.Material.Metal)
	local beam = Instance.new("SpotLight")
	beam.Face = Enum.NormalId.Back
	beam.Range = 50
	beam.Angle = 60
	beam.Brightness = 3
	beam.Parent = truck
	refs.Truck = truck

	for _, x in { -12, 12 } do
		Builder.part(map, "GatePost", Vector3.new(1.5, 12, 1.5), CFrame.new(x, 6, -205), WOOD, Enum.Material.Wood)
	end
	local sign = Builder.part(map, "GateSign", Vector3.new(26, 3, 0.6), CFrame.new(0, 12, -205), Color3.fromRGB(40, 80, 50), Enum.Material.Wood)
	Builder.label(sign, "HOLLOW PINES CAMPGROUND", Enum.NormalId.Back)
	Builder.label(sign, "HOLLOW PINES CAMPGROUND", Enum.NormalId.Front)

	refs.Spawns = {}
	for i = 0, 5 do
		table.insert(refs.Spawns, CFrame.new(ENTRANCE + Vector3.new(-8 + (i % 3) * 4, 3, -2 + math.floor(i / 3) * 4)) * CFrame.Angles(0, math.pi, 0))
	end
	refs.CampEntrance = Vector3.new(0, 0, -190)
end

local function buildOffice(map: Instance, refs)
	local office = Instance.new("Model")
	office.Name = "CampOffice"
	local function at(x, y, z)
		return CFrame.new(OFFICE + Vector3.new(x, y, z))
	end
	local wall = Color3.fromRGB(120, 92, 66)
	Builder.part(office, "Floor", Vector3.new(30, 1, 22), at(0, 0.5, 0), Color3.fromRGB(82, 62, 46), Enum.Material.WoodPlanks)
	Builder.part(office, "Roof", Vector3.new(33, 1, 25), at(0, 11.5, 0), Color3.fromRGB(70, 40, 36), Enum.Material.Slate)
	Builder.part(office, "WestWall", Vector3.new(1, 11, 22), at(-14.5, 6, 0), wall, Enum.Material.WoodPlanks)
	Builder.part(office, "NorthWall", Vector3.new(30, 11, 1), at(0, 6, -10.5), wall, Enum.Material.WoodPlanks)
	Builder.part(office, "SouthWall", Vector3.new(30, 11, 1), at(0, 6, 10.5), wall, Enum.Material.WoodPlanks)
	Builder.part(office, "EastWallN", Vector3.new(1, 11, 8), at(14.5, 6, -7), wall, Enum.Material.WoodPlanks)
	Builder.part(office, "EastWallS", Vector3.new(1, 11, 8), at(14.5, 6, 7), wall, Enum.Material.WoodPlanks)
	Builder.part(office, "EastWallTop", Vector3.new(1, 3, 6), at(14.5, 10, 0), wall, Enum.Material.WoodPlanks)
	local sign = Builder.part(office, "Sign", Vector3.new(0.4, 2.2, 10), at(15.2, 12.6, 0), Color3.fromRGB(40, 80, 50), Enum.Material.Wood)
	Builder.label(sign, "CAMP OFFICE", Enum.NormalId.Right)

	-- The generator still runs: warm light spills out of the door.
	for _, x in { -7, 7 } do
		local lamp = Builder.part(office, "Lamp", Vector3.new(1.6, 0.4, 1.6), at(x, 10.8, 0), Color3.fromRGB(255, 220, 160), Enum.Material.Neon)
		local light = Instance.new("PointLight")
		light.Range = 20
		light.Brightness = 1.3
		light.Color = Color3.fromRGB(255, 220, 160)
		light.Parent = lamp
	end

	refs.LostAndFound = Builder.part(office, "LostAndFound", Vector3.new(4, 3, 2.5), at(-11, 2.5, -7), Color3.fromRGB(70, 90, 140), Enum.Material.Plastic)
	Builder.label(refs.LostAndFound, "LOST & FOUND", Enum.NormalId.Front)
	Builder.part(office, "Desk", Vector3.new(6, 3, 3), at(-10, 2.5, 6), WOOD, Enum.Material.Wood)
	refs.HaleLog = Builder.part(office, "HaleLog", Vector3.new(1.6, 0.2, 1.2), at(-10, 4.1, 6), Color3.fromRGB(90, 60, 40), Enum.Material.Leather)
	refs.Noticeboard = Builder.part(office, "Noticeboard", Vector3.new(6, 4, 0.3), at(0, 6, -9.9), Color3.fromRGB(150, 120, 80), Enum.Material.Wood)
	Builder.label(refs.Noticeboard, "CAMP RULES\n1. Lights out at 10\n2. Stay quiet after dark\n3. Never go to the lake alone", Enum.NormalId.Back, Color3.fromRGB(40, 30, 20))

	refs.OfficeSafeZone = region(at(0, 6, 0), Vector3.new(28, 11, 20))
	refs.OfficeDoor = (at(18, 0, 0)).Position
	refs.OfficeCheckpoint = at(2, 3.5, 0)
	office.Parent = map
end

local function buildCampProps(map: Instance, refs)
	local props = Instance.new("Folder")
	props.Name = "CampProps"
	Builder.part(props, "FirePit", Vector3.new(8, 1, 8), CFrame.new(CAMP_CENTER + Vector3.new(0, 0.5, 0)), Color3.fromRGB(70, 70, 70), Enum.Material.Slate)
	Builder.part(props, "ShowerBlock", Vector3.new(18, 10, 12), CFrame.new(-10, 5, 60), Color3.fromRGB(150, 150, 140), Enum.Material.Concrete)
	Builder.part(props, "PicnicShelterRoof", Vector3.new(16, 1, 12), CFrame.new(-60, 9, 50), Color3.fromRGB(70, 40, 36), Enum.Material.Slate)
	for _, offset in { Vector3.new(-7, 0, -5), Vector3.new(7, 0, -5), Vector3.new(-7, 0, 5), Vector3.new(7, 0, 5) } do
		Builder.part(props, "ShelterPost", Vector3.new(1, 9, 1), CFrame.new(Vector3.new(-60, 4.5, 50) + offset), WOOD, Enum.Material.Wood)
	end
	Builder.part(props, "PicnicTable", Vector3.new(8, 2.6, 4), CFrame.new(-60, 1.3, 50), WOOD, Enum.Material.Wood)
	Builder.part(props, "CanoeRack", Vector3.new(12, 4, 3), CFrame.new(55, 2, 100), Color3.fromRGB(150, 60, 40), Enum.Material.Wood)
	Builder.part(props, "Woodpile", Vector3.new(6, 3, 3), CFrame.new(110, 1.5, -80), WOOD, Enum.Material.Wood)
	Builder.part(props, "Noticeboard2", Vector3.new(5, 6, 1), CFrame.new(20, 3, -180), WOOD, Enum.Material.Wood)
	props.Parent = map

	-- Where torn map pieces can turn up (four are used each run).
	refs.MapPieceSpots = {
		Vector3.new(0, 1.2, -52), -- by the fire pit
		Vector3.new(-10, 0.6, 52), -- shower block door
		Vector3.new(-60, 2.8, 50), -- picnic table
		Vector3.new(55, 0.6, 96), -- canoe rack
		Vector3.new(110, 0.6, -76), -- woodpile
		Vector3.new(20, 0.6, -176), -- noticeboard by the gate
	}
	for i = 1, 4 do
		local tent = refs.TentSpots[(i * 7) % #refs.TentSpots + 1]
		table.insert(refs.MapPieceSpots, tent)
	end

	refs.PatrolPoints = {
		CAMP_CENTER + Vector3.new(0, 0, 20),
		Vector3.new(-75, 0, -130),
		Vector3.new(75, 0, -130),
		Vector3.new(75, 0, 20),
		Vector3.new(-75, 0, 20),
		Vector3.new(0, 0, 70),
		Vector3.new(60, 0, 90),
		Vector3.new(-100, 0, 60),
		Vector3.new(110, 0, -60),
	}
end

local function buildLake(map: Instance, refs)
	local lake = Builder.part(map, "Lake", Vector3.new(700, 1, 220), CFrame.new(0, -0.4, LAKE_Z + 110), Color3.fromRGB(26, 44, 60), Enum.Material.Glass)
	lake.Transparency = 0.15
	lake.Reflectance = 0.25
	Builder.invisibleWall(map, Vector3.new(700, 40, 1), CFrame.new(0, 20, LAKE_Z + 1))

	local boathouse = Instance.new("Model")
	boathouse.Name = "Boathouse"
	local function at(x, y, z)
		return CFrame.new(BOATHOUSE + Vector3.new(x, y, z))
	end
	local wall = Color3.fromRGB(110, 80, 60)
	Builder.part(boathouse, "Floor", Vector3.new(18, 1, 14), at(0, 0.5, 0), Color3.fromRGB(82, 62, 46), Enum.Material.WoodPlanks)
	Builder.part(boathouse, "Roof", Vector3.new(20, 1, 16), at(0, 10.5, 0), Color3.fromRGB(56, 44, 40), Enum.Material.Slate)
	Builder.part(boathouse, "NorthWall", Vector3.new(18, 10, 1), at(0, 5.5, 6.5), wall, Enum.Material.WoodPlanks)
	Builder.part(boathouse, "WestWall", Vector3.new(1, 10, 14), at(-8.5, 5.5, 0), wall, Enum.Material.WoodPlanks)
	Builder.part(boathouse, "EastWall", Vector3.new(1, 10, 14), at(8.5, 5.5, 0), wall, Enum.Material.WoodPlanks)
	Builder.part(boathouse, "SouthWallL", Vector3.new(6, 10, 1), at(-6, 5.5, -6.5), wall, Enum.Material.WoodPlanks)
	Builder.part(boathouse, "SouthWallR", Vector3.new(6, 10, 1), at(6, 5.5, -6.5), wall, Enum.Material.WoodPlanks)
	Builder.part(boathouse, "SouthWallTop", Vector3.new(6, 3, 1), at(0, 9, -6.5), wall, Enum.Material.WoodPlanks)
	refs.BoathouseDoor = Builder.part(boathouse, "Door", Vector3.new(6, 7, 0.5), at(0, 4, -6.6), Color3.fromRGB(80, 56, 40), Enum.Material.Wood)
	refs.Padlock = Builder.part(boathouse, "Padlock", Vector3.new(0.8, 1, 0.4), at(1.8, 4, -7), Color3.fromRGB(180, 170, 150), Enum.Material.Metal)
	refs.FlareCase = Builder.part(boathouse, "FlareCase", Vector3.new(3, 1.2, 1.6), at(0, 2.6, 4), Color3.fromRGB(200, 60, 40), Enum.Material.Plastic)
	Builder.part(boathouse, "Shelf", Vector3.new(6, 2, 2), at(0, 1, 4.5), WOOD, Enum.Material.Wood)
	Builder.part(map, "Pier", Vector3.new(6, 1, 30), CFrame.new(BOATHOUSE + Vector3.new(14, 0.3, 20)), WOOD, Enum.Material.WoodPlanks)
	refs.BoathouseFront = (at(0, 0, -10)).Position
	boathouse.Parent = map
end

local function buildTower(map: Instance, refs)
	local tower = Instance.new("Model")
	tower.Name = "LookoutTower"
	local height = 40
	for _, offset in { Vector3.new(-6, 0, -6), Vector3.new(6, 0, -6), Vector3.new(-6, 0, 6), Vector3.new(6, 0, 6) } do
		Builder.part(tower, "Leg", Vector3.new(1.2, height, 1.2), CFrame.new(TOWER + offset + Vector3.new(0, height / 2, 0)), WOOD, Enum.Material.Wood)
	end
	Builder.part(tower, "Platform", Vector3.new(16, 1, 16), CFrame.new(TOWER + Vector3.new(0, height + 0.5, 0)), Color3.fromRGB(82, 62, 46), Enum.Material.WoodPlanks)
	for _, rail in {
		{ Vector3.new(0, 0, -7.5), Vector3.new(16, 3.5, 0.5) },
		{ Vector3.new(0, 0, 7.5), Vector3.new(16, 3.5, 0.5) },
		{ Vector3.new(-7.5, 0, 0), Vector3.new(0.5, 3.5, 16) },
		{ Vector3.new(7.5, 0, 2.5), Vector3.new(0.5, 3.5, 11) }, -- gap for the ladder
	} do
		Builder.part(tower, "Rail", rail[2], CFrame.new(TOWER + rail[1] + Vector3.new(0, height + 2.75, 0)), WOOD, Enum.Material.Wood)
	end
	Builder.part(tower, "Cabin", Vector3.new(8, 1, 8), CFrame.new(TOWER + Vector3.new(0, height + 8, 0)), Color3.fromRGB(56, 44, 40), Enum.Material.Slate)

	-- A TrussPart is climbable by default: walk into it to climb.
	local ladder = Instance.new("TrussPart")
	ladder.Name = "Ladder"
	ladder.Size = Vector3.new(2, height + 2, 2)
	ladder.CFrame = CFrame.new(TOWER + Vector3.new(9, (height + 2) / 2, -4.5))
	ladder.Anchored = true
	ladder.Color = Color3.fromRGB(120, 120, 120)
	ladder.Parent = tower

	refs.TowerBase = TOWER + Vector3.new(12, 0, -4.5)
	refs.FlareSpot = Builder.part(tower, "FlareMount", Vector3.new(1.4, 2, 1.4), CFrame.new(TOWER + Vector3.new(0, height + 2, 0)), Color3.fromRGB(200, 60, 40), Enum.Material.Metal)
	refs.TowerCheckpoint = CFrame.new(TOWER + Vector3.new(14, 3, -8))
	refs.TowerTopCenter = TOWER + Vector3.new(0, height + 1, 0)
	refs.WatcherCameo = CFrame.lookAt(TOWER + Vector3.new(-90, 0, -40), TOWER)
	tower.Parent = map
end

local function buildHelipad(map: Instance, refs)
	local pad = Builder.part(map, "Helipad", Vector3.new(30, 0.4, 30), CFrame.new(HELIPAD + Vector3.new(0, 0.2, 0)), Color3.fromRGB(60, 60, 64), Enum.Material.Concrete)
	pad.CastShadow = false
	for _, piece in {
		{ Vector3.new(-4, 0, 0), Vector3.new(2, 0.1, 12) },
		{ Vector3.new(4, 0, 0), Vector3.new(2, 0.1, 12) },
		{ Vector3.new(0, 0, 0), Vector3.new(8, 0.1, 2) },
	} do
		local mark = Builder.part(map, "HMark", piece[2], CFrame.new(HELIPAD + piece[1] + Vector3.new(0, 0.45, 0)), Color3.fromRGB(240, 240, 230), Enum.Material.SmoothPlastic)
		mark.CanCollide = false
	end
	local beacon = Builder.part(map, "LandingLight", Vector3.new(1, 1, 1), CFrame.new(HELIPAD + Vector3.new(0, 30, 0)), Color3.fromRGB(255, 255, 240), Enum.Material.Neon)
	beacon.Transparency = 1
	beacon.CanCollide = false
	local spot = Instance.new("SpotLight")
	spot.Face = Enum.NormalId.Bottom
	spot.Range = 60
	spot.Angle = 45
	spot.Brightness = 5
	spot.Enabled = false
	spot.Parent = beacon
	refs.LandingLight = { part = beacon, light = spot }
	refs.Helipad = HELIPAD
	refs.ExitZone = region(CFrame.new(HELIPAD + Vector3.new(0, 6, 0)), Vector3.new(30, 14, 30))
	refs.ExitHold = CFrame.new(HELIPAD + Vector3.new(0, 4, 0))
end

local function buildBounds(map: Instance)
	Builder.invisibleWall(map, Vector3.new(2, 80, 700), CFrame.new(-340, 40, 0))
	Builder.invisibleWall(map, Vector3.new(2, 80, 700), CFrame.new(340, 40, 0))
	Builder.invisibleWall(map, Vector3.new(700, 80, 2), CFrame.new(0, 40, -340))
end

function Chapter2Map.Build()
	local refs: any = {}
	local map = Instance.new("Model")
	map.Name = "Chapter2"
	refs.Map = map

	Builder.part(map, "Ground", Vector3.new(700, 2, 480), CFrame.new(0, -1, -100), Color3.fromRGB(46, 58, 40), Enum.Material.Grass)

	buildEntrance(map, refs)
	buildTents(map, refs)
	buildPools(map, refs)
	buildOffice(map, refs)
	buildCampProps(map, refs)
	buildLake(map, refs)
	buildTower(map, refs)
	buildHelipad(map, refs)
	buildBounds(map)

	-- Dirt paths tie the landmarks together.
	local paths = {
		{ refs.CampEntrance, CAMP_CENTER },
		{ CAMP_CENTER, refs.OfficeDoor },
		{ CAMP_CENTER, Vector3.new(0, 0, 80) },
		{ Vector3.new(0, 0, 80), refs.BoathouseFront },
		{ Vector3.new(0, 0, 80), refs.TowerBase },
		{ CAMP_CENTER, HELIPAD },
	}
	for _, segment in paths do
		local a, b = segment[1], segment[2]
		local strip = Builder.part(map, "Path", Vector3.new(7, 0.1, (b - a).Magnitude), CFrame.lookAt((a + b) / 2 + Vector3.new(0, 0.05, 0), b + Vector3.new(0, 0.05, 0)), DIRT, Enum.Material.Ground)
		strip.CanCollide = false
		strip.CastShadow = false
	end

	local function avoid(p: Vector3): boolean
		if p.Z > LAKE_Z - 8 then
			return true
		end
		if math.abs(p.X) < 14 and p.Z < -195 then
			return true -- road
		end
		if Vector3.new(p.X - CAMP_CENTER.X, 0, (p.Z - CAMP_CENTER.Z) * 0.8).Magnitude < 125 then
			return true
		end
		for _, landmark in { OFFICE, TOWER, BOATHOUSE, HELIPAD, ENTRANCE } do
			if (p - landmark).Magnitude < 35 then
				return true
			end
		end
		for _, segment in paths do
			if Builder.distanceToSegment(p, segment[1], segment[2]) < 9 then
				return true
			end
		end
		return false
	end
	Builder.forest(map, { seed = 2024, count = 420, center = Vector3.new(0, 0, -100), halfSize = Vector2.new(330, 235), avoid = avoid })

	map.Parent = workspace
	return refs
end

return Chapter2Map
