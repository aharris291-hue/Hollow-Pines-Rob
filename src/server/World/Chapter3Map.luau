-- Builds the Chapter 3 greybox: Millbrook, an empty logging village in the fog.
-- The helicopter in the field, a main street of houses, the lit general store
-- (safe), the three signals (chapel bell, school bell, sawmill whistle) and the
-- ferry dock on the lake.

local Builder = require(script.Parent.Builder)

local Chapter3Map = {}

local WOOD = Color3.fromRGB(96, 70, 48)
local DIRT = Color3.fromRGB(84, 70, 54)
local ROOF = Color3.fromRGB(70, 46, 40)

local FIELD = Vector3.new(0, 0, -235)
local STORE = Vector3.new(-42, 0, -60)
local CHAPEL = Vector3.new(-140, 0, 40)
local SCHOOL = Vector3.new(140, 0, -70)
local MILL = Vector3.new(125, 0, 115)
local DOCK = Vector3.new(0, 0, 170)
local LAKE_Z = 160

local function region(cframe: CFrame, size: Vector3)
	return { cframe = cframe, size = size }
end

local function path(map: Instance, a: Vector3, b: Vector3, width: number)
	local strip = Builder.part(map, "Path", Vector3.new(width, 0.1, (b - a).Magnitude + width * 0.5), CFrame.lookAt((a + b) / 2 + Vector3.new(0, 0.05, 0), b + Vector3.new(0, 0.05, 0)), DIRT, Enum.Material.Ground)
	strip.CanCollide = false
	strip.CastShadow = false
end

-- A closed house with a porch facing `facing` (+1 east, -1 west). Returns the porch spot.
local function house(folder: Instance, center: Vector3, facing: number, color: Color3): Vector3
	local base = CFrame.new(center) * CFrame.Angles(0, if facing > 0 then -math.pi / 2 else math.pi / 2, 0)
	local model = Instance.new("Model")
	model.Name = "House"
	Builder.part(model, "Walls", Vector3.new(20, 12, 18), base * CFrame.new(0, 6, 0), color, Enum.Material.WoodPlanks)
	local roof = Builder.part(model, "Roof", Vector3.new(22, 1, 20), base * CFrame.new(0, 12.5, 0), ROOF, Enum.Material.Slate)
	roof.CastShadow = true
	Builder.part(model, "Porch", Vector3.new(10, 1, 5), base * CFrame.new(0, 0.5, -11.5), WOOD, Enum.Material.WoodPlanks)
	local door = Builder.part(model, "Door", Vector3.new(4, 7, 0.4), base * CFrame.new(0, 4, -9.1), Color3.fromRGB(60, 44, 34), Enum.Material.Wood)
	door.CanCollide = false
	for _, x in { -6, 6 } do
		local window = Builder.part(model, "Window", Vector3.new(3, 3, 0.3), base * CFrame.new(x, 6.5, -9.1), Color3.fromRGB(30, 34, 40), Enum.Material.Glass)
		window.CanCollide = false
	end
	model.Parent = folder
	return (base * CFrame.new(math.random(-3, 3), 1.3, -12)).Position
end

local function buildField(map: Instance, refs)
	local field = Builder.part(map, "Field", Vector3.new(120, 0.2, 90), CFrame.new(FIELD + Vector3.new(0, 0.1, 0)), Color3.fromRGB(96, 104, 66), Enum.Material.Grass)
	field.CanCollide = false
	field.CastShadow = false

	local heli = Instance.new("Model")
	heli.Name = "Helicopter"
	Builder.part(heli, "Cabin", Vector3.new(8, 7, 12), CFrame.new(FIELD + Vector3.new(14, 3.6, -10)), Color3.fromRGB(200, 60, 50), Enum.Material.Metal)
	Builder.part(heli, "Tail", Vector3.new(1.6, 1.6, 16), CFrame.new(FIELD + Vector3.new(14, 5, 4)), Color3.fromRGB(200, 60, 50), Enum.Material.Metal)
	Builder.part(heli, "Rotor", Vector3.new(30, 0.3, 1.2), CFrame.new(FIELD + Vector3.new(14, 7.6, -10)) * CFrame.Angles(0, math.rad(25), 0), Color3.fromRGB(40, 40, 44), Enum.Material.Metal)
	for _, x in { -3, 3 } do
		Builder.part(heli, "Skid", Vector3.new(0.6, 0.6, 14), CFrame.new(FIELD + Vector3.new(14 + x, 0.3, -10)), Color3.fromRGB(60, 60, 64), Enum.Material.Metal)
	end
	refs.PilotSeat = Builder.part(heli, "PilotSeat", Vector3.new(2.4, 1, 2.4), CFrame.new(FIELD + Vector3.new(10.6, 1.4, -14)), Color3.fromRGB(40, 40, 44), Enum.Material.Fabric)
	heli.Parent = map

	refs.Spawns = {}
	for i = 0, 5 do
		table.insert(refs.Spawns, CFrame.new(FIELD + Vector3.new(-8 + (i % 3) * 4, 3, -4 + math.floor(i / 3) * 4)))
	end
	refs.VillageEdge = Vector3.new(0, 0, -170)
end

local function buildStreet(map: Instance, refs)
	local folder = Instance.new("Folder")
	folder.Name = "Houses"
	refs.TapeSpots = {}
	local colors = { Color3.fromRGB(150, 140, 120), Color3.fromRGB(120, 130, 140), Color3.fromRGB(140, 110, 90), Color3.fromRGB(110, 120, 100) }
	local index = 0
	for _, z in { -140, -95, -5, 40, 85 } do
		for _, side in { -1, 1 } do
			index += 1
			-- The general store takes the west slot at z = -60.
			local porch = house(folder, Vector3.new(side * 42, 0, z), -side, colors[index % #colors + 1])
			if index % 2 == 0 or z > 0 then
				table.insert(refs.TapeSpots, porch)
			end
		end
	end
	house(folder, Vector3.new(42, 0, -50), -1, colors[1])
	folder.Parent = map

	Builder.part(map, "Street", Vector3.new(26, 0.12, 340), CFrame.new(0, 0.06, -30), Color3.fromRGB(70, 66, 62), Enum.Material.Cobblestone).CanCollide = false
	-- Lampposts are dark; one flickers by the store.
	for _, z in { -150, -100, -50, 0, 50, 100 } do
		Builder.part(map, "Lamppost", Vector3.new(0.6, 12, 0.6), CFrame.new(14, 6, z), Color3.fromRGB(40, 40, 44), Enum.Material.Metal)
	end
	local well = Builder.part(map, "Well", Vector3.new(6, 3, 6), CFrame.new(0, 1.5, 20), Color3.fromRGB(110, 110, 110), Enum.Material.Slate)
	well.Shape = Enum.PartType.Cylinder
	well.CFrame = CFrame.new(0, 1.5, 20) * CFrame.Angles(0, 0, math.pi / 2)
	table.insert(refs.TapeSpots, Vector3.new(4, 1, 20))
end

local function buildStore(map: Instance, refs)
	local store = Instance.new("Model")
	store.Name = "GeneralStore"
	local function at(x, y, z)
		return CFrame.new(STORE + Vector3.new(x, y, z))
	end
	local wall = Color3.fromRGB(150, 120, 90)
	Builder.part(store, "Floor", Vector3.new(28, 1, 22), at(0, 0.5, 0), Color3.fromRGB(90, 70, 52), Enum.Material.WoodPlanks)
	Builder.part(store, "Roof", Vector3.new(31, 1, 25), at(0, 11.5, 0), ROOF, Enum.Material.Slate)
	Builder.part(store, "WestWall", Vector3.new(1, 11, 22), at(-13.5, 6, 0), wall, Enum.Material.WoodPlanks)
	Builder.part(store, "NorthWall", Vector3.new(28, 11, 1), at(0, 6, 10.5), wall, Enum.Material.WoodPlanks)
	Builder.part(store, "SouthWall", Vector3.new(28, 11, 1), at(0, 6, -10.5), wall, Enum.Material.WoodPlanks)
	Builder.part(store, "EastWallN", Vector3.new(1, 11, 7), at(13.5, 6, 7.5), wall, Enum.Material.WoodPlanks)
	Builder.part(store, "EastWallS", Vector3.new(1, 11, 7), at(13.5, 6, -7.5), wall, Enum.Material.WoodPlanks)
	Builder.part(store, "EastWallTop", Vector3.new(1, 3, 8), at(13.5, 10, 0), wall, Enum.Material.WoodPlanks)
	local sign = Builder.part(store, "Sign", Vector3.new(0.4, 2.4, 14), at(14.2, 12.8, 0), Color3.fromRGB(150, 40, 40), Enum.Material.Wood)
	Builder.label(sign, "MILLBROOK GENERAL STORE", Enum.NormalId.Right)
	for _, z in { -5, 5 } do
		local lamp = Builder.part(store, "Lamp", Vector3.new(1.6, 0.4, 1.6), at(0, 10.8, z), Color3.fromRGB(255, 225, 170), Enum.Material.Neon)
		local light = Instance.new("PointLight")
		light.Range = 22
		light.Brightness = 1.6
		light.Color = Color3.fromRGB(255, 225, 170)
		light.Parent = lamp
	end
	Builder.part(store, "Counter", Vector3.new(3, 3.4, 12), at(-6, 2.2, 0), WOOD, Enum.Material.Wood)
	refs.HaleTape = Builder.part(store, "TapeRecorder", Vector3.new(1.8, 0.8, 1.2), at(-6, 4.3, 2), Color3.fromRGB(40, 40, 46), Enum.Material.Plastic)
	refs.HandshakePoster = Builder.part(store, "Poster", Vector3.new(0.3, 5, 6), at(-12.9, 6, -3), Color3.fromRGB(235, 225, 200), Enum.Material.SmoothPlastic)
	Builder.label(refs.HandshakePoster, "MILLBROOK\nNEIGHBOURHOOD WATCH\n\nNot sure it's them?\nShake on it.", Enum.NormalId.Right, Color3.fromRGB(60, 40, 30))
	refs.StoreSafeZone = region(at(0, 6, 0), Vector3.new(26, 11, 20))
	refs.StoreDoor = at(17, 0, 0).Position
	refs.StoreCheckpoint = at(2, 3.5, 0)
	store.Parent = map
end

-- One of the three signals: a building and the thing you pull.
local function buildSignal(map: Instance, refs, id: string, center: Vector3, label: string, color: Color3, tall: boolean)
	local model = Instance.new("Model")
	model.Name = id
	local height = if tall then 30 else 14
	Builder.part(model, "Building", Vector3.new(24, 12, 18), CFrame.new(center + Vector3.new(0, 6, 0)), color, Enum.Material.WoodPlanks)
	Builder.part(model, "Roof", Vector3.new(26, 1, 20), CFrame.new(center + Vector3.new(0, 12.5, 0)), ROOF, Enum.Material.Slate)
	Builder.part(model, "Tower", Vector3.new(6, height, 6), CFrame.new(center + Vector3.new(0, height / 2, -12)), color, Enum.Material.WoodPlanks)
	local bell = Builder.part(model, "Bell", Vector3.new(3, 3, 3), CFrame.new(center + Vector3.new(0, height + 2, -12)), Color3.fromRGB(190, 150, 70), Enum.Material.Metal)
	bell.Shape = Enum.PartType.Ball
	local rope = Builder.part(model, "Rope", Vector3.new(0.5, 6, 0.5), CFrame.new(center + Vector3.new(0, 3, -15.5)), Color3.fromRGB(180, 160, 120), Enum.Material.Fabric)
	rope.CanCollide = false
	local plate = Builder.part(model, "Plate", Vector3.new(6, 2, 0.3), CFrame.new(center + Vector3.new(0, 8, -15.2)), Color3.fromRGB(40, 50, 40), Enum.Material.Wood)
	Builder.label(plate, label, Enum.NormalId.Front)
	model.Parent = map
	refs.Signals[id] = { part = rope, bell = bell, name = label, position = center + Vector3.new(0, 0, -18) }
end

local function buildLake(map: Instance, refs)
	local lake = Builder.part(map, "Lake", Vector3.new(700, 1, 200), CFrame.new(0, -0.4, LAKE_Z + 100), Color3.fromRGB(70, 92, 108), Enum.Material.Glass)
	lake.Transparency = 0.1
	lake.Reflectance = 0.2
	-- The shore is walled off except for a gap where the dock starts.
	Builder.invisibleWall(map, Vector3.new(343, 40, 1), CFrame.new(-178.5, 20, LAKE_Z + 1))
	Builder.invisibleWall(map, Vector3.new(343, 40, 1), CFrame.new(178.5, 20, LAKE_Z + 1))
	local dock = Builder.part(map, "Dock", Vector3.new(12, 1, 46), CFrame.new(DOCK + Vector3.new(0, 0.5, 13)), WOOD, Enum.Material.WoodPlanks)
	dock.CastShadow = true
	for _, x in { -6.5, 6.5 } do
		Builder.invisibleWall(map, Vector3.new(1, 20, 46), CFrame.new(DOCK + Vector3.new(x, 10, 13)))
	end
	Builder.invisibleWall(map, Vector3.new(14, 20, 1), CFrame.new(DOCK + Vector3.new(0, 10, 36.5)))

	local ferry = Instance.new("Model")
	ferry.Name = "Ferry"
	local hull = Builder.part(ferry, "Hull", Vector3.new(16, 4, 30), CFrame.new(DOCK + Vector3.new(0, 1.5, 300)), Color3.fromRGB(230, 230, 220), Enum.Material.Metal)
	local cabin = Builder.part(ferry, "Cabin", Vector3.new(10, 6, 10), CFrame.new(DOCK + Vector3.new(0, 6.5, 306)), Color3.fromRGB(60, 90, 120), Enum.Material.Metal)
	local lamp = Builder.part(ferry, "Lamp", Vector3.new(1, 1, 1), CFrame.new(DOCK + Vector3.new(0, 10, 300)), Color3.fromRGB(255, 240, 200), Enum.Material.Neon)
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Front
	light.Range = 60
	light.Brightness = 4
	light.Parent = lamp
	for _, part in { cabin, lamp } do
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = hull
		weld.Part1 = part
		weld.Parent = part
		part.Anchored = false
	end
	ferry.PrimaryPart = hull
	ferry.Parent = map
	refs.Ferry = ferry
	refs.FerryDocked = CFrame.new(DOCK + Vector3.new(0, 1.5, 52))
	refs.Dock = DOCK + Vector3.new(0, 0, 30)
	refs.ExitZone = region(CFrame.new(DOCK + Vector3.new(0, 6, 30)), Vector3.new(12, 12, 14))
	refs.ExitHold = CFrame.new(DOCK + Vector3.new(0, 6, 52))
end

local function buildBounds(map: Instance)
	Builder.invisibleWall(map, Vector3.new(2, 80, 700), CFrame.new(-320, 40, 0))
	Builder.invisibleWall(map, Vector3.new(2, 80, 700), CFrame.new(320, 40, 0))
	Builder.invisibleWall(map, Vector3.new(700, 80, 2), CFrame.new(0, 40, -320))
end

function Chapter3Map.Build()
	local refs: any = {}
	local map = Instance.new("Model")
	map.Name = "Chapter3"
	refs.Map = map
	refs.Signals = {}

	Builder.part(map, "Ground", Vector3.new(700, 2, 500), CFrame.new(0, -1, -80), Color3.fromRGB(70, 82, 56), Enum.Material.Grass)

	buildField(map, refs)
	buildStreet(map, refs)
	buildStore(map, refs)
	buildSignal(map, refs, "Chapel", CHAPEL, "CHAPEL BELL", Color3.fromRGB(200, 196, 186), true)
	buildSignal(map, refs, "School", SCHOOL, "SCHOOL BELL", Color3.fromRGB(170, 70, 60), false)
	buildSignal(map, refs, "Mill", MILL, "SAWMILL WHISTLE", Color3.fromRGB(120, 100, 80), false)
	buildLake(map, refs)
	buildBounds(map)

	local paths = {
		{ refs.VillageEdge, Vector3.new(0, 0, -150) },
		{ Vector3.new(0, 0, 15), refs.Signals.Chapel.position },
		{ Vector3.new(0, 0, -70), refs.Signals.School.position },
		{ Vector3.new(0, 0, 110), refs.Signals.Mill.position },
		{ Vector3.new(0, 0, 120), DOCK },
		{ FIELD, refs.VillageEdge },
	}
	for _, segment in paths do
		path(map, segment[1], segment[2], 8)
	end

	-- Where the copy can step out of the fog: along the street and the paths.
	refs.CopySpawns = {}
	for z = -200, 140, 20 do
		for _, x in { -20, 20 } do
			table.insert(refs.CopySpawns, Vector3.new(x, 0, z))
		end
	end
	for _, segment in paths do
		for t = 0.25, 0.75, 0.25 do
			table.insert(refs.CopySpawns, segment[1]:Lerp(segment[2], t))
		end
	end

	local landmarks = { STORE, CHAPEL, SCHOOL, MILL, FIELD + Vector3.new(14, 0, -10) }
	local function avoid(p: Vector3): boolean
		if p.Z > LAKE_Z - 8 then
			return true
		end
		if math.abs(p.X) < 70 and p.Z > -175 and p.Z < 125 then
			return true -- the village
		end
		if (p - FIELD).Magnitude < 70 then
			return true
		end
		for _, landmark in landmarks do
			if (p - landmark).Magnitude < 38 then
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
	Builder.forest(map, { seed = 3033, count = 360, center = Vector3.new(0, 0, -80), halfSize = Vector2.new(310, 235), avoid = avoid })

	map.Parent = workspace
	return refs
end

return Chapter3Map
