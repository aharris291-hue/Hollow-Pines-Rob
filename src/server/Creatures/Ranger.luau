-- The Ranger (Chapter 2): what is left of Ranger Hale. Blind under the hat brim,
-- it hunts by sound and by light. It patrols, walks to anything it hears,
-- searches, and gives chase when it sees someone close in front of it (or
-- further away if their light is on). Hiding in a tent, staying in the office,
-- or climbing out of reach makes it lose you.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Creatures = require(Shared.Config.Creatures)
local GameConfig = require(Shared.Config.GameConfig)
local Hearing = require(Shared.Util.Hearing)
local Mover = require(script.Parent.Mover)

local Ranger = {}
Ranger.__index = Ranger

local CONFIG = Creatures.Ranger
local HIDDEN_CFRAME = CFrame.new(0, -400, 0) -- above FallenPartsDestroyHeight
local COAT = Color3.fromRGB(46, 58, 40)
local SKIN = Color3.fromRGB(20, 18, 18)

-- `pivot` makes the part a joint the client can animate (Gait): "top" swings
-- from its top end (hips, shoulders), "bottom" from its bottom end (the neck).
-- `holder` welds the part to another part instead of the root (a hat to the head).
local function weldedPart(model: Model, root: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?, pivot: string?, holder: BasePart?)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.Fabric
	if shape then
		part.Shape = shape
	end
	part.CanCollide = false
	part.CanTouch = false
	part.Massless = true
	part.CFrame = root.CFrame * offset
	if pivot then
		local hinge = CFrame.new(0, if pivot == "top" then size.Y / 2 else -size.Y / 2, 0)
		local joint = Instance.new("Motor6D")
		joint.Name = name .. "Joint"
		joint.Part0 = root
		joint.Part1 = part
		joint.C0 = offset * hinge
		joint.C1 = hinge
		joint.Parent = part
	else
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = holder or root
		weld.Part1 = part
		weld.Parent = part
	end
	part.Parent = model
	return part
end

local function buildModel(): (Model, PointLight)
	local model = Instance.new("Model")
	model.Name = "TheRanger"

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.Anchored = true
	root.CFrame = CFrame.new(0, 4.5, 0)
	root.Parent = model
	model.PrimaryPart = root

	weldedPart(model, root, "Coat", Vector3.new(2.6, 4.6, 1.4), CFrame.new(0, 0.6, 0), COAT)
	local head = weldedPart(model, root, "Head", Vector3.new(1.4, 1.5, 1.4), CFrame.new(0, 3.6, 0), SKIN, Enum.Material.SmoothPlastic, nil, "bottom")
	-- The wide hat throws its face into permanent shadow.
	weldedPart(model, root, "HatBrim", Vector3.new(0.2, 3.6, 3.6), CFrame.new(0, 4.3, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(110, 86, 52), Enum.Material.Fabric, Enum.PartType.Cylinder, nil, head)
	weldedPart(model, root, "HatCrown", Vector3.new(1.1, 1.6, 1.6), CFrame.new(0, 4.9, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(110, 86, 52), Enum.Material.Fabric, Enum.PartType.Cylinder, nil, head)
	weldedPart(model, root, "Badge", Vector3.new(0.4, 0.4, 0.1), CFrame.new(-0.6, 1.8, -0.72), Color3.fromRGB(200, 170, 80), Enum.Material.Metal)
	weldedPart(model, root, "LeftArm", Vector3.new(0.6, 4.2, 0.6), CFrame.new(-1.6, 0.6, 0), COAT, nil, nil, "top")
	local lanternArm = weldedPart(model, root, "RightArm", Vector3.new(0.6, 4.2, 0.6), CFrame.new(1.6, 1.2, -0.8) * CFrame.Angles(math.rad(-35), 0, 0), COAT, nil, nil, "top")
	weldedPart(model, root, "LeftLeg", Vector3.new(0.8, 3.5, 0.8), CFrame.new(-0.5, -2.75, 0), Color3.fromRGB(30, 30, 28), nil, nil, "top")
	weldedPart(model, root, "RightLeg", Vector3.new(0.8, 3.5, 0.8), CFrame.new(0.5, -2.75, 0), Color3.fromRGB(30, 30, 28), nil, nil, "top")

	local lantern = weldedPart(model, root, "Lantern", Vector3.new(0.9, 1.2, 0.9), CFrame.new(1.7, -0.6, -2), Color3.fromRGB(255, 170, 80), Enum.Material.Neon, nil, nil, lanternArm)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 160, 70)
	light.Range = 20
	light.Brightness = 2
	light.Shadows = true
	light.Parent = lantern

	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.HipHeight = 3.5
	humanoid.WalkSpeed = CONFIG.patrolSpeed
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	humanoid.Parent = model

	model:SetAttribute("Creature", "Ranger")
	model:PivotTo(HIDDEN_CFRAME)
	return model, light
end

-- context = {
--   getTargets: () -> { Player },
--   getNoises: () -> { noise },
--   hasLight: (Player) -> boolean,
--   isSafe: (Vector3) -> boolean,
--   patrolPoints: { Vector3 },
--   onSpotted: (Player) -> (),        it started chasing this player
--   onLost: (Player, hidden: boolean) -> (),
--   onHeard: (noise) -> (),
--   onCatch: (Player) -> (),
-- }
function Ranger.new(context)
	local self = setmetatable({}, Ranger)
	self.context = context
	self.model, self.lantern = buildModel()
	self.root = self.model.PrimaryPart
	self.humanoid = self.model:FindFirstChildOfClass("Humanoid")
	self.mover = Mover.new(self.humanoid, self.root, CONFIG.height)
	self.mode = "Hidden"
	self.visible = false
	self.patrolIndex = 1
	self.goal = nil
	self.target = nil
	self.searchUntil = 0
	self.stunnedUntil = 0
	self.pauseUntil = 0
	self.speedBonus = 0
	self.lastNoise = nil
	self.raycastParams = RaycastParams.new()
	self.raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	self.model.Parent = workspace
	return self
end

function Ranger:Destroy()
	self.mode = "Destroyed"
	self.model:Destroy()
end

function Ranger:Position(): Vector3?
	return if self.visible then self.root.Position else nil
end

function Ranger:PlaceAt(position: Vector3)
	self.root.Anchored = true
	self.model:PivotTo(CFrame.new(position.X, 4.5, position.Z))
	self.root.Anchored = false
	self.root:SetNetworkOwner(nil)
	self.visible = true
end

-- Modes: Hidden, Patrol, Investigate, Search, Chase, Guard (stand watch at a
-- point), Hunt (finale: always chases the nearest player it can reach).
function Ranger:SetMode(mode: string, goal: Vector3?)
	self.mode = mode
	self.goal = goal
	if mode == "Hidden" then
		self.visible = false
		self.root.Anchored = true
		self.model:PivotTo(HIDDEN_CFRAME)
	elseif not self.visible then
		self:PlaceAt(goal or self.context.patrolPoints[1])
	end
	if mode == "Hunt" then
		self.speedBonus = 0
	end
end

function Ranger:Stun(seconds: number)
	self.stunnedUntil = os.clock() + seconds
	self.lantern.Enabled = false
	task.delay(seconds, function()
		if self.lantern.Parent then
			self.lantern.Enabled = true
		end
	end)
end

function Ranger:AddSpeed(amount: number)
	self.speedBonus += amount
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Players it cannot reach: hidden, in the office, or up the tower.
function Ranger:_unreachable(player: Player, root: BasePart): boolean
	return player:GetAttribute("Hidden") == true
		or self.context.isSafe(root.Position)
		or root.Position.Y > CONFIG.elevatedHeight
end

function Ranger:_canSee(player: Player): boolean
	local root = rootOf(player)
	if not root or self:_unreachable(player, root) then
		return false
	end
	local eye = self.root.Position + Vector3.new(0, 3, 0)
	local offset = root.Position - eye
	local range = if self.context.hasLight(player) then CONFIG.litSightRange else CONFIG.sightRange
	if offset.Magnitude > range then
		return false
	end
	local facing = self.root.CFrame.LookVector
	local flat = Vector3.new(offset.X, 0, offset.Z)
	if flat.Magnitude > 4 and math.deg(math.acos(math.clamp(facing:Dot(flat.Unit), -1, 1))) > CONFIG.sightAngle then
		return false
	end
	self.raycastParams.FilterDescendantsInstances = { self.model, player.Character }
	local hit = workspace:Raycast(eye, offset, self.raycastParams)
	return hit == nil
end

function Ranger:_spot(targets: { Player }): Player?
	for _, player in targets do
		if self:_canSee(player) then
			return player
		end
	end
	return nil
end

function Ranger:_listen()
	local noise = Hearing.loudest(self.root.Position, self.context.getNoises(), os.clock(), GameConfig.Noise.MemorySeconds, CONFIG.hearingMultiplier)
	if noise and noise ~= self.lastNoise then
		self.lastNoise = noise
		return noise
	end
	return nil
end

function Ranger:_startChase(player: Player)
	if self.target ~= player then
		self.context.onSpotted(player)
	end
	self.mode = "Chase"
	self.target = player
end

function Ranger:_tryCatch(player: Player, distance: number): boolean
	if distance <= CONFIG.catchDistance then
		self.context.onCatch(player)
		self.pauseUntil = os.clock() + CONFIG.pauseAfterCatch
		self.target = nil
		self.mode = if self.mode == "Hunt" then "Hunt" else "Search"
		self.searchUntil = os.clock() + CONFIG.searchTime
		return true
	end
	return false
end

function Ranger:Update(dt: number)
	if self.mode == "Hidden" or self.mode == "Destroyed" then
		return
	end
	local now = os.clock()
	if now < self.stunnedUntil or now < self.pauseUntil then
		self.mover:Stop()
		return
	end
	local targets = self.context.getTargets()

	if self.mode == "Hunt" then
		local best, bestDistance = nil, math.huge
		for _, player in targets do
			local root = rootOf(player)
			if root and not self:_unreachable(player, root) then
				local distance = (root.Position - self.root.Position).Magnitude
				if distance < bestDistance then
					best, bestDistance = player, distance
				end
			end
		end
		if best and not self:_tryCatch(best, bestDistance) then
			self.mover:Step(dt, (rootOf(best) :: BasePart).Position, CONFIG.chaseSpeed + self.speedBonus)
		elseif not best then
			self.mover:Stop()
		end
		return
	end

	if self.mode == "Chase" then
		local target = self.target
		local root = target and target.Parent and rootOf(target)
		local lost = not root
			or target:GetAttribute("Downed")
			or target:GetAttribute("Escaped")
			or self:_unreachable(target, root)
			or (root.Position - self.root.Position).Magnitude > CONFIG.loseDistance
		if lost then
			if target then
				self.context.onLost(target, target:GetAttribute("Hidden") == true)
			end
			self.mode = "Search"
			self.goal = if root then root.Position else self.root.Position
			self.searchUntil = now + CONFIG.searchTime
			self.target = nil
			return
		end
		local distance = (root.Position - self.root.Position).Magnitude
		if not self:_tryCatch(target, distance) then
			self.mover:Step(dt, root.Position, CONFIG.chaseSpeed + self.speedBonus)
		end
		return
	end

	-- Patrol / Investigate / Search / Guard all react to sight and sound.
	local seen = self:_spot(targets)
	if seen then
		self:_startChase(seen)
		return
	end
	local heard = self:_listen()
	if heard and self.mode ~= "Guard" then
		self.mode = "Investigate"
		self.goal = heard.position
		self.context.onHeard(heard)
	end

	if self.mode == "Investigate" then
		if self.mover:Step(dt, self.goal, CONFIG.investigateSpeed) < 4 then
			self.mode = "Search"
			self.searchUntil = now + CONFIG.searchTime
		end
	elseif self.mode == "Search" then
		local remaining = self.mover:Step(dt, self.goal or self.root.Position, CONFIG.patrolSpeed)
		if remaining < 4 then
			-- Turn slowly on the spot, lantern sweeping.
			self.root.CFrame *= CFrame.Angles(0, math.rad(60) * dt, 0)
		end
		if now > self.searchUntil then
			self.mode = "Patrol"
		end
	elseif self.mode == "Guard" then
		if self.mover:Step(dt, self.goal, CONFIG.patrolSpeed) < 4 then
			self.root.CFrame *= CFrame.Angles(0, math.rad(40) * dt, 0)
		end
	else -- Patrol
		local points = self.context.patrolPoints
		local goal = points[self.patrolIndex]
		if self.mover:Step(dt, goal, CONFIG.patrolSpeed) < 5 then
			self.patrolIndex = math.random(#points)
		end
	end
end

return Ranger
