-- The Hollow One (Chapter 4): the heart of the forest. A vast hollow pine with
-- one glowing eye. It never moves. Its gaze sweeps the clearing like a
-- lighthouse beam (glowing streaks on the ground show where it is looking);
-- anyone caught in it in the open for too long is pulled down. Standing stones,
-- trees and buildings block its gaze.
--
-- Modes: Dormant (asleep), Awake (sweeping), Angry (sweeping faster, finale).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Creatures = require(Shared.Config.Creatures)
local Gaze = require(Shared.Util.Gaze)

local HollowOne = {}
HollowOne.__index = HollowOne

local CONFIG = Creatures.HollowOne
local EYE_HEIGHT = 22
local BARK = Color3.fromRGB(52, 42, 36)
local GLOW = Color3.fromRGB(255, 214, 120)

local function part(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material
	p.Anchored = true
	if shape then
		p.Shape = shape
	end
	p.Parent = parent
	return p
end

local function buildTree(center: Vector3): (Model, Part, Model)
	local model = Instance.new("Model")
	model.Name = "TheHollowOne"
	local up = CFrame.Angles(0, 0, math.pi / 2)
	part(model, "Trunk", Vector3.new(70, 26, 26), CFrame.new(center + Vector3.new(0, 35, 0)) * up, BARK, Enum.Material.Wood, Enum.PartType.Cylinder)
	for i = 1, 7 do
		local angle = i / 7 * math.pi * 2
		local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
		-- Roots spread out over the ground, branches reach up and out.
		part(model, "Root", Vector3.new(4, 4, 30), CFrame.lookAt(center + direction * 20 + Vector3.new(0, 1, 0), center + direction * 40), BARK, Enum.Material.Wood)
		part(model, "Branch", Vector3.new(3, 3, 26), CFrame.lookAt(center + direction * 14 + Vector3.new(0, 62 + (i % 3) * 4, 0), center + direction * 30 + Vector3.new(0, 75, 0)), BARK, Enum.Material.Wood)
	end
	local hollow = part(model, "Hollow", Vector3.new(10, 14, 2), CFrame.new(center + Vector3.new(0, EYE_HEIGHT, -12.6)), Color3.fromRGB(8, 6, 6), Enum.Material.SmoothPlastic)
	hollow.CanCollide = false
	local eye = part(model, "Eye", Vector3.new(4, 4, 4), CFrame.new(center + Vector3.new(0, EYE_HEIGHT, 0)), GLOW, Enum.Material.Neon, Enum.PartType.Ball)
	eye.CanCollide = false
	eye.CanQuery = false
	local light = Instance.new("PointLight")
	light.Range = 40
	light.Brightness = 2
	light.Color = GLOW
	light.Parent = eye

	-- The beam: glowing streaks fanned out on the ground, turned as one piece.
	local beam = Instance.new("Model")
	beam.Name = "Gaze"
	local pivot = part(beam, "Pivot", Vector3.new(1, 1, 1), CFrame.new(center + Vector3.new(0, 0.3, 0)), GLOW, Enum.Material.Neon)
	pivot.Transparency = 1
	beam.PrimaryPart = pivot
	for step = -2, 2 do
		local offset = math.rad(CONFIG.gazeHalfAngle * step / 2)
		local streak = part(beam, "Streak", Vector3.new(1.6, 0.15, CONFIG.gazeRange - 14), pivot.CFrame * CFrame.Angles(0, -offset, 0) * CFrame.new(0, 0, (CONFIG.gazeRange + 14) / 2), GLOW, Enum.Material.Neon)
		streak.Transparency = if step == 0 then 0.35 else 0.6
		streak.CanCollide = false
		streak.CanQuery = false
		streak.CastShadow = false
	end
	beam.Parent = model
	model:SetAttribute("Creature", "HollowOne")
	return model, eye, beam
end

-- context = {
--   getTargets: () -> { Player },
--   isSafe: (Vector3) -> boolean,
--   onSeen: (Player, dt: number) -> (),   every tick a player is in the gaze
--   onCatch: (Player) -> (),
-- }
function HollowOne.new(context, center: Vector3)
	local self = setmetatable({}, HollowOne)
	self.context = context
	self.center = center
	self.model, self.eye, self.beam = buildTree(center)
	self.mode = "Dormant"
	self.heading = 180
	self.exposure = {}
	self.stunnedUntil = 0
	self.raycastParams = RaycastParams.new()
	self.raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	self.beam.Parent = nil -- hidden until it wakes
	self.model.Parent = workspace
	return self
end

function HollowOne:Position(): Vector3?
	return if self.mode == "Dormant" then nil else self.center
end

function HollowOne:SetMode(mode: string)
	self.mode = mode
	self.model:SetAttribute("Mode", mode) -- the client sways its branches harder when Angry
	self.beam.Parent = if mode == "Dormant" then nil else self.model
	self.eye.Color = if mode == "Angry" then Color3.fromRGB(255, 120, 80) else GLOW
	if mode == "Dormant" then
		for player in self.exposure do
			if player.Parent then
				player:SetAttribute("Gaze", nil)
			end
		end
		table.clear(self.exposure)
	end
end

-- A camera flash makes it close its eye for a moment.
function HollowOne:Stun(seconds: number)
	self.stunnedUntil = os.clock() + seconds
end

function HollowOne:AddSpeed(_amount: number) end

function HollowOne:_canSee(player: Player): boolean
	local character = player.Character
	local head = character and character:FindFirstChild("Head") :: BasePart?
	if not head or self.context.isSafe(head.Position) then
		return false
	end
	if not Gaze.inBeam(self.center, self.heading, CONFIG.gazeHalfAngle, CONFIG.gazeRange, head.Position) then
		return false
	end
	local eye = self.center + Vector3.new(0, EYE_HEIGHT, 0)
	self.raycastParams.FilterDescendantsInstances = { self.model, character }
	return workspace:Raycast(eye, head.Position - eye, self.raycastParams) == nil
end

function HollowOne:Update(dt: number)
	if self.mode == "Dormant" or self.mode == "Destroyed" then
		return
	end
	local closed = os.clock() < self.stunnedUntil
	self.eye.Transparency = if closed then 0.8 else 0
	if closed then
		return
	end
	local speed = if self.mode == "Angry" then CONFIG.angrySweepSpeed else CONFIG.sweepSpeed
	self.heading = (self.heading + speed * dt + 180) % 360 - 180
	self.beam:PivotTo(CFrame.new(self.center + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, math.rad(self.heading), 0))
	self.eye.CFrame = CFrame.new(self.center + Vector3.new(0, EYE_HEIGHT, 0)) * CFrame.Angles(0, math.rad(self.heading), 0) * CFrame.new(0, 0, 12)

	local seenNow = {}
	for _, player in self.context.getTargets() do
		local seen = self:_canSee(player)
		seenNow[player] = true
		if seen then
			self.context.onSeen(player, dt)
		end
		local exposure, caught = Gaze.step(self.exposure[player] or 0, seen, dt, CONFIG.exposureFall, CONFIG.exposureToCatch)
		self.exposure[player] = exposure
		player:SetAttribute("Gaze", if exposure > 0 then math.floor(exposure / CONFIG.exposureToCatch * 100) / 100 else nil)
		if caught then
			self.context.onCatch(player)
		end
	end
	for player in self.exposure do
		if not seenNow[player] then
			self.exposure[player] = nil
			if player.Parent then
				player:SetAttribute("Gaze", nil)
			end
		end
	end
end

function HollowOne:Destroy()
	self:SetMode("Dormant")
	self.mode = "Destroyed"
	self.model:Destroy()
end

return HollowOne
