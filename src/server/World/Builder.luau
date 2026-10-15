-- Small helpers for building greybox geometry from code. Hand-built maps can
-- replace any of this later; services only rely on the returned references.

local Builder = {}

function Builder.part(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

function Builder.invisibleWall(parent: Instance, size: Vector3, cframe: CFrame): Part
	local wall = Builder.part(parent, "InvisibleWall", size, cframe, Color3.new(), Enum.Material.SmoothPlastic)
	wall.Transparency = 1
	wall.CanQuery = false
	wall.CastShadow = false
	return wall
end

function Builder.label(part: BasePart, text: string, face: Enum.NormalId, textColor: Color3?)
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0.6
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Merriweather
	label.TextScaled = true
	label.TextColor3 = textColor or Color3.fromRGB(240, 228, 200)
	label.Text = text
	label.Parent = gui
	gui.Parent = part
	return gui
end

function Builder.prompt(part: BasePart, action: string, objectText: string, hold: number?): ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = action
	prompt.ObjectText = objectText
	prompt.HoldDuration = hold or 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	return prompt
end

function Builder.tree(parent: Instance, position: Vector3, height: number, rng: Random)
	local tree = Instance.new("Model")
	tree.Name = "Pine"
	local trunkRadius = height / 22
	local trunk = Builder.part(tree, "Trunk", Vector3.new(height, trunkRadius * 2, trunkRadius * 2),
		CFrame.new(position + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2),
		Color3.fromRGB(64 + rng:NextInteger(-8, 8), 46, 34), Enum.Material.Wood)
	trunk.Shape = Enum.PartType.Cylinder

	local green = Color3.fromRGB(28 + rng:NextInteger(-6, 6), 52 + rng:NextInteger(-8, 8), 36)
	local tiers = 3
	for tier = 1, tiers do
		local radius = (height / 4.2) * (1 - (tier - 1) / (tiers + 0.6))
		local y = height * (0.45 + 0.18 * (tier - 1))
		local foliage = Builder.part(tree, "Needles", Vector3.new(height * 0.22, radius * 2, radius * 2),
			CFrame.new(position + Vector3.new(0, y, 0)) * CFrame.Angles(0, 0, math.pi / 2), green, Enum.Material.Grass)
		foliage.Shape = Enum.PartType.Cylinder
		foliage.CastShadow = tier == 1
	end
	tree.Parent = parent
	return tree
end

export type ForestOptions = {
	seed: number,
	count: number,
	center: Vector3,
	innerRadius: number?, -- ring placement when set with outerRadius
	outerRadius: number?,
	halfSize: Vector2?, -- rectangle placement otherwise
	avoid: ((Vector3) -> boolean)?,
}

function Builder.forest(parent: Instance, options: ForestOptions)
	local folder = Instance.new("Folder")
	folder.Name = "Forest"
	local rng = Random.new(options.seed)
	local placed, attempts = 0, 0
	while placed < options.count and attempts < options.count * 8 do
		attempts += 1
		local position
		if options.outerRadius then
			local angle = rng:NextNumber(0, math.pi * 2)
			local radius = rng:NextNumber(options.innerRadius or 0, options.outerRadius)
			position = options.center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
		else
			local half = options.halfSize :: Vector2
			position = options.center + Vector3.new(rng:NextNumber(-half.X, half.X), 0, rng:NextNumber(-half.Y, half.Y))
		end
		if not (options.avoid and options.avoid(position)) then
			Builder.tree(folder, position, rng:NextNumber(20, 36), rng)
			placed += 1
		end
	end
	folder.Parent = parent
	return folder
end

-- Distance from point p to segment ab on the XZ plane.
function Builder.distanceToSegment(p: Vector3, a: Vector3, b: Vector3): number
	local ap = Vector3.new(p.X - a.X, 0, p.Z - a.Z)
	local ab = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local lengthSq = ab:Dot(ab)
	local t = if lengthSq > 0 then math.clamp(ap:Dot(ab) / lengthSq, 0, 1) else 0
	return (ap - ab * t).Magnitude
end

return Builder
