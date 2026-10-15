-- The Watcher: a tall, faceless figure that is only ever seen at the edge of the
-- light. While stalking it never moves when looked at; it slips away instead and
-- reappears a little closer. In the final chase it hunts the group.

local PathfindingService = game:GetService("PathfindingService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Creatures = require(Shared.Config.Creatures)

local Watcher = {}
Watcher.__index = Watcher

local CONFIG = Creatures.Watcher
local HIDDEN_CFRAME = CFrame.new(0, -400, 0) -- above FallenPartsDestroyHeight
local SKIN = Color3.fromRGB(14, 13, 16)

-- `pivot` makes the part a joint the client can animate (Gait): "top" swings
-- from its top end (hips, shoulders), "bottom" from its bottom end (the neck).
local function weldedPart(model: Model, root: BasePart, name: string, size: Vector3, offset: CFrame, color: Color3, material: Enum.Material?, pivot: string?)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.CanCollide = false
	part.CanQuery = true
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
		weld.Part0 = root
		weld.Part1 = part
		weld.Parent = part
	end
	part.Parent = model
	return part
end

local function buildModel(): Model
	local model = Instance.new("Model")
	model.Name = "TheWatcher"

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Transparency = 1
	root.CanCollide = false
	root.Anchored = true
	root.CFrame = CFrame.new(0, 6, 0)
	root.Parent = model
	model.PrimaryPart = root

	-- Proportions are deliberately wrong: long limbs, narrow body, small head.
	weldedPart(model, root, "Torso", Vector3.new(2.2, 5.5, 1.2), CFrame.new(0, 2.6, 0), SKIN)
	local head = weldedPart(model, root, "Head", Vector3.new(1.6, 2, 1.6), CFrame.new(0, 6.3, 0), SKIN, nil, "bottom")
	head.Shape = Enum.PartType.Ball
	weldedPart(model, root, "LeftArm", Vector3.new(0.5, 7, 0.5), CFrame.new(-1.5, 1.2, 0) * CFrame.Angles(0, 0, math.rad(-4)), SKIN, nil, "top")
	weldedPart(model, root, "RightArm", Vector3.new(0.5, 7, 0.5), CFrame.new(1.5, 1.2, 0) * CFrame.Angles(0, 0, math.rad(4)), SKIN, nil, "top")
	weldedPart(model, root, "LeftLeg", Vector3.new(0.6, 5, 0.6), CFrame.new(-0.6, -3.5, 0), SKIN, nil, "top")
	weldedPart(model, root, "RightLeg", Vector3.new(0.6, 5, 0.6), CFrame.new(0.6, -3.5, 0), SKIN, nil, "top")
	for _, side in { -0.35, 0.35 } do
		local eye = weldedPart(model, root, "Eye", Vector3.new(0.18, 0.18, 0.1), CFrame.new(side, 6.4, -0.78), Color3.fromRGB(220, 230, 255), Enum.Material.Neon)
		eye.CanQuery = false
		-- The eyes ride on the head so they follow it when it tilts.
		local weld = eye:FindFirstChildOfClass("WeldConstraint") :: WeldConstraint
		weld.Part0 = head
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.HipHeight = 5
	humanoid.WalkSpeed = CONFIG.chaseSpeed
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	humanoid.Parent = model

	model:SetAttribute("Creature", "Watcher")
	model:PivotTo(HIDDEN_CFRAME)
	return model
end

-- context = {
--   getTargets: () -> { Player },   players it may notice or chase
--   getLook: (Player) -> Vector3?,   camera direction reported by the client
--   onSpotted: (Player) -> (),
--   onCatch: (Player) -> (),
-- }
function Watcher.new(context)
	local self = setmetatable({}, Watcher)
	self.context = context
	self.model = buildModel()
	self.root = self.model.PrimaryPart
	self.humanoid = self.model:FindFirstChildOfClass("Humanoid")
	self.mode = "Hidden"
	self.visible = false
	self.seenTime = {}
	self.spottedBy = {}
	self.relocateTimer = 0
	self.stalkDistance = CONFIG.maxStalkDistance
	self.stunnedUntil = 0
	self.pauseUntil = 0
	self.speedBonus = 0
	self.raycastParams = RaycastParams.new()
	self.raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	self.model.Parent = workspace
	return self
end

function Watcher:Destroy()
	self.mode = "Destroyed"
	self.model:Destroy()
end

function Watcher:Position(): Vector3?
	if not self.visible then
		return nil
	end
	return self.root.Position
end

local function groundCFrame(position: Vector3, lookAt: Vector3): CFrame
	local base = Vector3.new(position.X, 6, position.Z)
	return CFrame.lookAt(base, Vector3.new(lookAt.X, 6, lookAt.Z))
end

function Watcher:_place(cframe: CFrame)
	self.root.Anchored = true
	self.model:PivotTo(cframe)
	self.visible = true
	table.clear(self.seenTime)
	table.clear(self.spottedBy)
end

function Watcher:Hide()
	self.visible = false
	self.root.Anchored = true
	self.model:PivotTo(HIDDEN_CFRAME)
end

function Watcher:SetMode(mode: string)
	self.mode = mode
	if mode == "Hidden" then
		self:Hide()
	elseif mode == "Stalk" then
		self.stalkDistance = CONFIG.maxStalkDistance
		self.relocateTimer = 3
		self:Hide()
	elseif mode == "Chase" then
		self.speedBonus = 0
		self.root.Anchored = false
		self.root:SetNetworkOwner(nil)
		self.visible = true
	end
end

-- Scripted appearance, e.g. the first sighting from the trail.
function Watcher:Reveal(cframe: CFrame)
	self.mode = "Reveal"
	self:_place(groundCFrame(cframe.Position, cframe.Position + cframe.LookVector))
end

function Watcher:Stun(seconds: number)
	if self.mode == "Chase" then
		self.stunnedUntil = os.clock() + seconds
		self.humanoid:MoveTo(self.root.Position)
	elseif self.visible then
		self:Hide()
		self.relocateTimer = seconds + 4
	end
end

function Watcher:AddSpeed(amount: number)
	self.speedBonus += amount
end

local function characterParts(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local head = character and character:FindFirstChild("Head")
	return character, root, head
end

-- Is this player looking at the Watcher with nothing in between?
function Watcher:_isLookedAtBy(player: Player): boolean
	local character, root, head = characterParts(player)
	if not character or not root or not head then
		return false
	end
	local eye = head.Position
	local target = self.root.Position + Vector3.new(0, 4, 0)
	local offset = target - eye
	if offset.Magnitude > CONFIG.lookRange then
		return false
	end
	local look = self.context.getLook(player) or root.CFrame.LookVector
	local angle = math.deg(math.acos(math.clamp(look.Unit:Dot(offset.Unit), -1, 1)))
	if angle > CONFIG.lookAngle then
		return false
	end
	self.raycastParams.FilterDescendantsInstances = { character, self.model }
	local hit = workspace:Raycast(eye, offset, self.raycastParams)
	return hit == nil or (hit.Position - eye).Magnitude >= offset.Magnitude - 2
end

function Watcher:_groupCenter(targets: { Player }): Vector3?
	local sum, count = Vector3.zero, 0
	for _, player in targets do
		local _, root = characterParts(player)
		if root then
			sum += root.Position
			count += 1
		end
	end
	if count == 0 then
		return nil
	end
	return sum / count
end

function Watcher:_inAnyonesView(position: Vector3, targets: { Player }): boolean
	for _, player in targets do
		local _, root = characterParts(player)
		if root then
			local look = self.context.getLook(player) or root.CFrame.LookVector
			local offset = position - root.Position
			if offset.Magnitude < CONFIG.lookRange and look.Unit:Dot(offset.Unit) > math.cos(math.rad(60)) then
				return true
			end
		end
	end
	return false
end

function Watcher:_relocate(targets: { Player })
	local center = self:_groupCenter(targets)
	if not center then
		return
	end
	self.stalkDistance = math.max(CONFIG.minStalkDistance, self.stalkDistance - CONFIG.approachStep)
	for _ = 1, 16 do
		local angle = math.random() * math.pi * 2
		local position = center + Vector3.new(math.cos(angle), 0, math.sin(angle)) * self.stalkDistance
		-- Appear where nobody is looking, so players only notice it on turning around.
		if not self:_inAnyonesView(position, targets) then
			self:_place(groundCFrame(position, center))
			return
		end
	end
end

function Watcher:_updateSightings(dt: number, targets: { Player }): boolean
	local seenLongEnough = false
	for _, player in targets do
		if self:_isLookedAtBy(player) then
			self.seenTime[player] = (self.seenTime[player] or 0) + dt
			if not self.spottedBy[player] then
				self.spottedBy[player] = true
				self.context.onSpotted(player)
			end
			if self.seenTime[player] >= CONFIG.vanishAfterSeen then
				seenLongEnough = true
			end
		end
		local _, root = characterParts(player)
		if root and (root.Position - self.root.Position).Magnitude < 15 then
			seenLongEnough = true -- never let a stalking Watcher be walked up to
		end
	end
	return seenLongEnough
end

function Watcher:_nearestTarget(targets: { Player }): (Player?, number)
	local best, bestDistance = nil, math.huge
	for _, player in targets do
		local _, root = characterParts(player)
		if root then
			local distance = (root.Position - self.root.Position).Magnitude
			if distance < bestDistance then
				best, bestDistance = player, distance
			end
		end
	end
	return best, bestDistance
end

function Watcher:_chase(dt: number, targets: { Player })
	local now = os.clock()
	if now < self.stunnedUntil or now < self.pauseUntil then
		self.humanoid.WalkSpeed = 0
		return
	end
	self.humanoid.WalkSpeed = CONFIG.chaseSpeed + self.speedBonus

	local target, distance = self:_nearestTarget(targets)
	if not target then
		self.humanoid:MoveTo(self.root.Position)
		return
	end
	local _, targetRoot = characterParts(target)
	if distance <= CONFIG.catchDistance then
		self.context.onCatch(target)
		-- A short pause after a catch gives everyone else a fair chance to run.
		self.pauseUntil = now + 3
		return
	end

	self.pathTimer = (self.pathTimer or 0) - dt
	if distance < 20 then
		self.humanoid:MoveTo(targetRoot.Position)
		return
	end
	if self.pathTimer <= 0 then
		self.pathTimer = 0.8
		local path = PathfindingService:CreatePath({ AgentRadius = 2.5, AgentHeight = 11, AgentCanJump = false })
		local ok = pcall(path.ComputeAsync, path, self.root.Position, targetRoot.Position)
		if ok and path.Status == Enum.PathStatus.Success then
			self.waypoints = path:GetWaypoints()
			self.waypointIndex = 2
		else
			self.waypoints = nil
		end
	end
	local waypoint = self.waypoints and self.waypoints[self.waypointIndex]
	if waypoint then
		if (waypoint.Position - self.root.Position).Magnitude < 4 then
			self.waypointIndex += 1
			waypoint = self.waypoints[self.waypointIndex]
		end
	end
	self.humanoid:MoveTo(if waypoint then waypoint.Position else targetRoot.Position)
end

function Watcher:Update(dt: number)
	local targets = self.context.getTargets()
	if self.mode == "Stalk" then
		if self.visible then
			if self:_updateSightings(dt, targets) then
				self:Hide()
				self.stalkDistance = CONFIG.maxStalkDistance
				self.relocateTimer = math.random(CONFIG.relocateInterval[1], CONFIG.relocateInterval[2])
			end
		end
		self.relocateTimer -= dt
		if self.relocateTimer <= 0 then
			self.relocateTimer = math.random(CONFIG.relocateInterval[1], CONFIG.relocateInterval[2])
			self:_relocate(targets)
		end
	elseif self.mode == "Reveal" then
		if self:_updateSightings(dt, targets) then
			self:SetMode("Stalk")
		end
	elseif self.mode == "Chase" then
		self:_chase(dt, targets)
	end
end

return Watcher
