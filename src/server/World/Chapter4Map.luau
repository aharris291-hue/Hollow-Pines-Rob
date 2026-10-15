-- Builds the Chapter 4 greybox: the far shore. The ferry dock and the old
-- boathouse cabin (lit, safe), a trail into the oldest part of the forest, three
-- groves where the lost adults stand frozen as wood, and the Hollow: a clearing
-- of standing stones around the giant hollow pine, with three stone braziers.

local Builder = require(script.Parent.Builder)

local Chapter4Map = {}

local WOOD = Color3.fromRGB(96, 70, 48)
local DIRT = Color3.fromRGB(84, 70, 54)
local STONE = Color3.fromRGB(120, 120, 116)

local DOCK = Vector3.new(0, 0, -250)
local CABIN = Vector3.new(-40, 0, -205)
local HOLLOW = Vector3.new(0, 0, 90)
local GROVES = {
	{ id = "Driver", name = "Mr. Dorsey", role = "the bus driver", position = Vector3.new(-190, 0, -60), color = Color3.fromRGB(60, 70, 110) },
	{ id = "Ranger", name = "Ranger Hale", role = "the ranger", position = Vector3.new(190, 0, -40), color = Color3.fromRGB(46, 58, 40) },
	{ id = "Pilot", name = "Captain Reyes", role = "the pilot", position = Vector3.new(-170, 0, 190), color = Color3.fromRGB(150, 60, 50) },
}

local function region(cframe: CFrame, size: Vector3)
	return { cframe = cframe, size = size }
end

local function path(map: Instance, a: Vector3, b: Vector3, width: number)
	local strip = Builder.part(map, "Path", Vector3.new(width, 0.1, (b - a).Magnitude + width * 0.5), CFrame.lookAt((a + b) / 2 + Vector3.new(0, 0.05, 0), b + Vector3.new(0, 0.05, 0)), DIRT, Enum.Material.Ground)
	strip.CanCollide = false
	strip.CastShadow = false
end

local function buildShore(map: Instance, refs)
	local lake = Builder.part(map, "Lake", Vector3.new(700, 1, 160), CFrame.new(0, -0.4, -370), Color3.fromRGB(70, 92, 108), Enum.Material.Glass)
	lake.Transparency = 0.1
	lake.Reflectance = 0.2
	Builder.invisibleWall(map, Vector3.new(343, 40, 1), CFrame.new(-178.5, 20, -291))
	Builder.invisibleWall(map, Vector3.new(343, 40, 1), CFrame.new(178.5, 20, -291))
	Builder.part(map, "Dock", Vector3.new(12, 1, 46), CFrame.new(DOCK + Vector3.new(0, 0.5, -17)), WOOD, Enum.Material.WoodPlanks)
	for _, x in { -6.5, 6.5 } do
		Builder.invisibleWall(map, Vector3.new(1, 20, 46), CFrame.new(DOCK + Vector3.new(x, 10, -17)))
	end
	Builder.invisibleWall(map, Vector3.new(14, 20, 1), CFrame.new(DOCK + Vector3.new(0, 10, -40.5)))
	local ferry = Builder.part(map, "Ferry", Vector3.new(16, 4, 30), CFrame.new(DOCK + Vector3.new(0, 1.5, -58)), Color3.fromRGB(230, 230, 220), Enum.Material.Metal)
	ferry.CanCollide = false

	refs.Spawns = {}
	for i = 0, 5 do
		table.insert(refs.Spawns, CFrame.new(DOCK + Vector3.new(-4 + (i % 3) * 4, 3, -30 + math.floor(i / 3) * 5)))
	end
	refs.Dock = DOCK + Vector3.new(0, 0, -25)
	refs.ExitZone = region(CFrame.new(DOCK + Vector3.new(0, 6, -32)), Vector3.new(12, 12, 16))
	refs.ExitHold = CFrame.new(DOCK + Vector3.new(0, 6, -58))
	refs.FerrymanNote = Builder.part(map, "FerrymanNote", Vector3.new(1.6, 0.2, 1.2), CFrame.new(DOCK + Vector3.new(3, 1.1, -10)), Color3.fromRGB(235, 225, 200), Enum.Material.SmoothPlastic)
end

local function buildCabin(map: Instance, refs)
	local cabin = Instance.new("Model")
	cabin.Name = "Cabin"
	local function at(x, y, z)
		return CFrame.new(CABIN + Vector3.new(x, y, z))
	end
	local wall = Color3.fromRGB(110, 84, 60)
	Builder.part(cabin, "Floor", Vector3.new(24, 1, 18), at(0, 0.5, 0), Color3.fromRGB(82, 62, 46), Enum.Material.WoodPlanks)
	Builder.part(cabin, "Roof", Vector3.new(27, 1, 21), at(0, 10.5, 0), Color3.fromRGB(70, 46, 40), Enum.Material.Slate)
	Builder.part(cabin, "WestWall", Vector3.new(1, 10, 18), at(-11.5, 5.5, 0), wall, Enum.Material.WoodPlanks)
	Builder.part(cabin, "NorthWall", Vector3.new(24, 10, 1), at(0, 5.5, 8.5), wall, Enum.Material.WoodPlanks)
	Builder.part(cabin, "SouthWall", Vector3.new(24, 10, 1), at(0, 5.5, -8.5), wall, Enum.Material.WoodPlanks)
	Builder.part(cabin, "EastWallN", Vector3.new(1, 10, 6), at(11.5, 5.5, 6), wall, Enum.Material.WoodPlanks)
	Builder.part(cabin, "EastWallS", Vector3.new(1, 10, 6), at(11.5, 5.5, -6), wall, Enum.Material.WoodPlanks)
	Builder.part(cabin, "EastWallTop", Vector3.new(1, 3, 6), at(11.5, 9, 0), wall, Enum.Material.WoodPlanks)
	local lamp = Builder.part(cabin, "Lamp", Vector3.new(1.6, 0.4, 1.6), at(0, 9.8, 0), Color3.fromRGB(255, 225, 170), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Range = 22
	light.Brightness = 1.6
	light.Color = Color3.fromRGB(255, 225, 170)
	light.Parent = lamp
	Builder.part(cabin, "Table", Vector3.new(6, 3, 4), at(-5, 2.5, 0), WOOD, Enum.Material.Wood)
	refs.Journal = Builder.part(cabin, "Journal", Vector3.new(1.6, 0.3, 1.2), at(-5, 4.15, 0), Color3.fromRGB(90, 40, 30), Enum.Material.Leather)
	refs.CabinSafeZone = region(at(0, 5.5, 0), Vector3.new(22, 10, 16))
	refs.CabinDoor = at(15, 0, 0).Position
	refs.CabinCheckpoint = at(2, 3.5, 0)
	cabin.Parent = map
end

-- A lost adult, turned to wood and wrapped in roots.
local function buildStatue(parent: Instance, position: Vector3, color: Color3): Model
	local model = Instance.new("Model")
	model.Name = "Statue"
	local wood = Color3.fromRGB(110, 84, 58)
	local body = Builder.part(model, "Body", Vector3.new(2.4, 4.2, 1.4), CFrame.new(position + Vector3.new(0, 4.6, 0)), wood, Enum.Material.Wood)
	body:SetAttribute("TrueColor", color)
	Builder.part(model, "Head", Vector3.new(1.4, 1.4, 1.4), CFrame.new(position + Vector3.new(0, 7.5, 0)), wood, Enum.Material.Wood)
	for _, x in { -0.6, 0.6 } do
		Builder.part(model, "Leg", Vector3.new(0.9, 2.6, 0.9), CFrame.new(position + Vector3.new(x, 1.3, 0)), wood, Enum.Material.Wood)
	end
	for _, side in { -1, 1 } do
		Builder.part(model, "Arm", Vector3.new(0.7, 3.6, 0.7), CFrame.new(position + Vector3.new(side * 1.6, 5.2, -0.4)) * CFrame.Angles(math.rad(-25), 0, math.rad(side * 10)), wood, Enum.Material.Wood)
	end
	for i = 1, 5 do
		local angle = i / 5 * math.pi * 2
		local root = Builder.part(model, "Root", Vector3.new(0.6, 6, 0.6), CFrame.new(position + Vector3.new(math.cos(angle) * 1.6, 3, math.sin(angle) * 1.2)) * CFrame.Angles(math.rad(12), angle, 0), Color3.fromRGB(52, 42, 36), Enum.Material.Wood)
		root.Name = "Vine"
	end
	model.PrimaryPart = body
	model.Parent = parent
	return model
end

local function buildGroves(map: Instance, refs)
	refs.Lost = {}
	for _, grove in GROVES do
		local folder = Instance.new("Folder")
		folder.Name = grove.id .. "Grove"
		-- A ring of pale birches marks each grove.
		for i = 1, 9 do
			local angle = i / 9 * math.pi * 2
			Builder.part(folder, "Birch", Vector3.new(1.6, 26, 1.6), CFrame.new(grove.position + Vector3.new(math.cos(angle) * 18, 13, math.sin(angle) * 18)), Color3.fromRGB(225, 222, 210), Enum.Material.Wood)
		end
		local statue = buildStatue(folder, grove.position, grove.color)
		folder.Parent = map
		table.insert(refs.Lost, { id = grove.id, name = grove.name, role = grove.role, statue = statue, position = grove.position })
	end
end

local function buildHollow(map: Instance, refs)
	local floor = Builder.part(map, "HollowFloor", Vector3.new(270, 0.2, 270), CFrame.new(HOLLOW + Vector3.new(0, 0.1, 0)), Color3.fromRGB(64, 60, 50), Enum.Material.Mud)
	floor.CanCollide = false
	floor.CastShadow = false

	-- Standing stones: the only cover from its gaze.
	local stones = Instance.new("Folder")
	stones.Name = "StandingStones"
	local rng = Random.new(404)
	for ring, radius in { 40, 66, 92, 116 } do
		local count = 6 + ring * 2
		for i = 1, count do
			local angle = (i + ring * 0.5) / count * math.pi * 2
			local position = HOLLOW + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
			local height = rng:NextNumber(8, 12)
			local stone = Builder.part(stones, "Stone", Vector3.new(rng:NextNumber(5, 7), height, rng:NextNumber(3, 4)), CFrame.lookAt(position + Vector3.new(0, height / 2, 0), HOLLOW + Vector3.new(0, height / 2, 0)), STONE, Enum.Material.Slate)
			stone.CastShadow = true
		end
	end
	stones.Parent = map

	refs.Braziers = {}
	for i, angle in { 200, 320, 80 } do
		local radians = math.rad(angle)
		local position = HOLLOW + Vector3.new(math.sin(radians) * 78, 0, math.cos(radians) * 78)
		local bowl = Builder.part(map, "Brazier", Vector3.new(4, 4, 4), CFrame.new(position + Vector3.new(0, 2, 0)), Color3.fromRGB(80, 80, 84), Enum.Material.Slate)
		local fire = Builder.part(map, "BrazierFire", Vector3.new(3, 2, 3), CFrame.new(position + Vector3.new(0, 5, 0)), Color3.fromRGB(255, 160, 60), Enum.Material.Neon)
		fire.Transparency = 1
		fire.CanCollide = false
		local light = Instance.new("PointLight")
		light.Range = 30
		light.Brightness = 3
		light.Color = Color3.fromRGB(255, 170, 80)
		light.Enabled = false
		light.Parent = fire
		refs.Braziers[i] = { part = bowl, fire = fire, light = light, lit = false }
	end
	refs.HollowCenter = HOLLOW
	refs.HollowEdge = HOLLOW + Vector3.new(0, 0, -135)
end

local function buildBounds(map: Instance)
	Builder.invisibleWall(map, Vector3.new(2, 80, 700), CFrame.new(-320, 40, 0))
	Builder.invisibleWall(map, Vector3.new(2, 80, 700), CFrame.new(320, 40, 0))
	Builder.invisibleWall(map, Vector3.new(700, 80, 2), CFrame.new(0, 40, 300))
end

function Chapter4Map.Build()
	local refs: any = {}
	local map = Instance.new("Model")
	map.Name = "Chapter4"
	refs.Map = map

	Builder.part(map, "Ground", Vector3.new(700, 2, 600), CFrame.new(0, -1, 0), Color3.fromRGB(56, 70, 46), Enum.Material.Grass)
	buildShore(map, refs)
	buildCabin(map, refs)
	buildGroves(map, refs)
	buildHollow(map, refs)
	buildBounds(map)

	local junction = Vector3.new(0, 0, -100)
	local paths = {
		{ DOCK, junction },
		{ refs.CabinDoor, DOCK + Vector3.new(0, 0, 20) },
		{ junction, refs.Lost[1].position },
		{ junction, refs.Lost[2].position },
		{ refs.Lost[1].position, refs.Lost[3].position },
		{ junction, refs.HollowEdge },
	}
	for _, segment in paths do
		path(map, segment[1], segment[2], 8)
	end
	refs.Junction = junction

	local function avoid(p: Vector3): boolean
		if p.Z < -280 then
			return true
		end
		if (p - HOLLOW).Magnitude < 140 or (p - CABIN).Magnitude < 32 or (p - DOCK).Magnitude < 40 then
			return true
		end
		for _, lost in refs.Lost do
			if (p - lost.position).Magnitude < 26 then
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
	-- The old forest is dense: stay on the paths.
	Builder.forest(map, { seed = 4044, count = 520, center = Vector3.new(0, 0, 0), halfSize = Vector2.new(310, 280), avoid = avoid })

	map.Parent = workspace
	return refs
end

return Chapter4Map
