-- Hand-made animation for the creatures, drawn on each player's own screen.
-- No uploaded animations: legs and arms swing from the joints the server builds
-- (Motor6D.Transform is local to this client), heads tilt and turn while they
-- stand still, and The Hollow One's branches sway. Each creature moves a little
-- differently on purpose:
--   The Watcher: long slow strides, arms hardly swing; standing, its head tilts.
--   The Ranger: a heavy walk, lantern arm held out; standing, he turns his head
--     to listen.
--   The Copy: legs walk but its arms hang dead still, head cocked a bit wrong.

local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Gait = require(Shared.Util.Gait)

local CreatureAnimator = {}

type Style = Gait.Style & { idle: string, holdRight: boolean? }

local STYLES: { [string]: Style } = {
	Watcher = { stride = 10, legSwing = 26, armSwing = 6, bob = 0.15, runSpeed = 17, idle = "Tilt" },
	Ranger = { stride = 6, legSwing = 30, armSwing = 20, bob = 0.12, runSpeed = 16, idle = "Listen", holdRight = true },
	Copy = { stride = 5, legSwing = 34, armSwing = 0, bob = 0.08, runSpeed = 16, idle = "Cocked" },
}

-- Joint names: the part rigs (Watcher, Ranger), then R15 and R6 avatars (Copy).
local JOINTS = {
	LeftLeg = { "LeftLegJoint", "LeftHip", "Left Hip" },
	RightLeg = { "RightLegJoint", "RightHip", "Right Hip" },
	LeftArm = { "LeftArmJoint", "LeftShoulder", "Left Shoulder" },
	RightArm = { "RightArmJoint", "RightShoulder", "Right Shoulder" },
	Head = { "HeadJoint", "Neck" },
}

local RAD = math.rad
local MAX_STEP = 6 -- studs in one frame; more than this is a teleport

type Tracked = {
	model: Model,
	style: Style,
	root: BasePart,
	joints: { [string]: Motor6D },
	r6: boolean,
	phase: number,
	amount: number,
	last: Vector3,
	seed: number,
}

local tracked: { [Model]: Tracked } = {}
local trees: { [Model]: { { part: BasePart, base: CFrame, offset: number } } } = {}

local function findJoint(model: Model, names: { string }): Motor6D?
	for _, name in names do
		local joint = model:FindFirstChild(name, true)
		if joint and joint:IsA("Motor6D") then
			return joint
		end
	end
	return nil
end

local function swing(entry: Tracked, angle: number): CFrame
	-- R6 hips and shoulders turn about their own Z axis; everything else about X.
	return if entry.r6 then CFrame.Angles(0, 0, -angle) else CFrame.Angles(angle, 0, 0)
end

local function animate(entry: Tracked, now: number, dt: number)
	local position = entry.root.Position
	local speed = Gait.speedBetween(entry.last, position, dt, MAX_STEP)
	entry.last = position
	local style = entry.style
	entry.phase = Gait.advance(entry.phase, speed, dt, style)
	entry.amount = Gait.blend(entry.amount, speed, dt, style, 8)
	local pose = Gait.pose(entry.phase, entry.amount, style)
	local joints = entry.joints

	-- R6 joints are mirrored left to right, so one angle swings them opposite ways.
	local mirror = if entry.r6 then 1 else -1
	if joints.LeftLeg then
		joints.LeftLeg.Transform = swing(entry, pose.leg)
	end
	if joints.RightLeg then
		joints.RightLeg.Transform = swing(entry, mirror * pose.leg)
	end
	if style.armSwing > 0 then
		if joints.LeftArm then
			joints.LeftArm.Transform = swing(entry, pose.arm)
		end
		if joints.RightArm then
			-- A held lantern only rocks a little.
			local arm = if style.holdRight then pose.arm * 0.25 else pose.arm
			joints.RightArm.Transform = swing(entry, mirror * arm)
		end
	end

	local head = joints.Head
	if head and not entry.r6 then
		local still = 1 - entry.amount
		local t = now + entry.seed
		local idle
		if style.idle == "Tilt" then
			-- Slowly tips its head over, like it's curious about you.
			idle = CFrame.Angles(0, 0, RAD(16) * math.sin(t * 0.35) * still)
		elseif style.idle == "Listen" then
			idle = CFrame.Angles(0, RAD(40) * math.sin(t * 0.5) * still, 0)
		else
			idle = CFrame.Angles(RAD(4), 0, RAD(9) + RAD(2) * math.sin(t * 3))
		end
		head.Transform = CFrame.new(0, pose.bob, 0) * idle
	end
end

local function sway(parts, model: Model, now: number)
	local angry = model:GetAttribute("Mode") == "Angry"
	local strength = if angry then RAD(6) else RAD(2.5)
	local rate = if angry then 1.6 else 0.6
	for _, branch in parts do
		local t = now * rate + branch.offset
		branch.part.CFrame = branch.base * CFrame.Angles(strength * math.sin(t), 0, strength * 0.5 * math.cos(t * 0.7))
	end
end

local function track(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local kind = model:GetAttribute("Creature")
	if kind == "HollowOne" then
		local parts = {}
		for index, child in model:GetChildren() do
			if child:IsA("BasePart") and child.Name == "Branch" then
				table.insert(parts, { part = child, base = child.CFrame, offset = index * 1.7 })
			end
		end
		trees[model] = parts
	else
		local style = STYLES[kind]
		if not style then
			return
		end
		local root = model:WaitForChild("HumanoidRootPart", 5)
		if not root or not root:IsA("BasePart") or not model:IsDescendantOf(workspace) then
			return
		end
		local joints = {}
		for key, names in JOINTS do
			joints[key] = findJoint(model, names)
		end
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		tracked[model] = {
			model = model,
			style = style,
			root = root,
			joints = joints,
			r6 = kind == "Copy" and humanoid ~= nil and humanoid.RigType == Enum.HumanoidRigType.R6,
			phase = 0,
			amount = 0,
			last = root.Position,
			seed = math.random() * 10,
		}
	end
	model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(workspace) then
			tracked[model :: Model] = nil
			trees[model :: Model] = nil
		end
	end)
end

function CreatureAnimator:Start()
	-- Attributes arrive with the model; its parts may stream in a moment later.
	workspace.ChildAdded:Connect(function(child)
		task.spawn(track, child)
	end)
	for _, child in workspace:GetChildren() do
		task.spawn(track, child)
	end

	RunService.Stepped:Connect(function(_, dt)
		local now = os.clock()
		for _, entry in tracked do
			animate(entry, now, dt)
		end
		for model, parts in trees do
			sway(parts, model, now)
		end
	end)
end

return CreatureAnimator
