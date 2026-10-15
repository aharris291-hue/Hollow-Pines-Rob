-- Walks a Humanoid creature towards a goal, using pathfinding when the goal is
-- far and a straight line when it is close. Call Step every tick.

local PathfindingService = game:GetService("PathfindingService")

local Mover = {}
Mover.__index = Mover

function Mover.new(humanoid: Humanoid, root: BasePart, agentHeight: number)
	local self = setmetatable({}, Mover)
	self.humanoid = humanoid
	self.root = root
	self.agent = { AgentRadius = 2.5, AgentHeight = agentHeight, AgentCanJump = false }
	self.timer = 0
	self.waypoints = nil
	self.index = 0
	self.goal = nil
	return self
end

function Mover:Stop()
	self.goal = nil
	self.waypoints = nil
	self.humanoid:MoveTo(self.root.Position)
end

-- Returns the distance left to the goal.
function Mover:Step(dt: number, goal: Vector3, speed: number): number
	self.humanoid.WalkSpeed = speed
	local distance = (goal - self.root.Position) * Vector3.new(1, 0, 1)
	local remaining = distance.Magnitude
	if remaining < 18 then
		self.waypoints = nil
		self.humanoid:MoveTo(goal)
		return remaining
	end

	self.timer -= dt
	if self.timer <= 0 or not self.goal or (self.goal - goal).Magnitude > 8 then
		self.timer = 1
		self.goal = goal
		local path = PathfindingService:CreatePath(self.agent)
		local ok = pcall(path.ComputeAsync, path, self.root.Position, goal)
		if ok and path.Status == Enum.PathStatus.Success then
			self.waypoints = path:GetWaypoints()
			self.index = math.min(2, #self.waypoints)
		else
			self.waypoints = nil
		end
	end

	local waypoint = self.waypoints and self.waypoints[self.index]
	if waypoint and (waypoint.Position - self.root.Position).Magnitude < 4 then
		self.index += 1
		waypoint = self.waypoints[self.index]
	end
	self.humanoid:MoveTo(if waypoint then waypoint.Position else goal)
	return remaining
end

return Mover
