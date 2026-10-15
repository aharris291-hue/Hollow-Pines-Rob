-- Pure maths for the creatures' hand-made walk cycles (no uploaded animations).
-- A creature's stride phase advances with how fast it moves; `amount` eases
-- between standing (0) and full stride (1) so starts and stops look smooth.

local Gait = {}

export type Style = {
	stride: number, -- studs per full step cycle
	legSwing: number, -- degrees each leg swings forward and back
	armSwing: number, -- degrees each arm swings (0 = arms hang still)
	bob: number, -- studs the body rises at each footfall
	runSpeed: number, -- speed (studs/s) that counts as a full stride
}

export type Pose = { leg: number, arm: number, bob: number }

-- Advances the stride phase (radians) for a creature moving at `speed`.
function Gait.advance(phase: number, speed: number, dt: number, style: Style): number
	if speed <= 0 then
		return phase
	end
	return (phase + speed * dt / style.stride * math.pi * 2) % (math.pi * 2)
end

-- Eases `amount` towards how much of a full stride `speed` is, at `rate` per second.
function Gait.blend(amount: number, speed: number, dt: number, style: Style, rate: number): number
	local target = math.clamp(speed / style.runSpeed, 0, 1)
	local t = 1 - math.exp(-rate * dt)
	return amount + (target - amount) * t
end

-- Swing angles (radians) and body bob for the left side; the right side mirrors.
function Gait.pose(phase: number, amount: number, style: Style): Pose
	local swing = math.sin(phase)
	return {
		leg = math.rad(style.legSwing) * swing * amount,
		arm = -math.rad(style.armSwing) * swing * amount,
		bob = style.bob * math.abs(math.sin(phase)) * amount,
	}
end

-- Horizontal speed between two positions; a jump this far in one frame is a
-- teleport (the creature slipping away), not walking, and reads as standing.
function Gait.speedBetween(from: Vector3, to: Vector3, dt: number, maxStep: number): number
	if dt <= 0 then
		return 0
	end
	local dx, dz = to.X - from.X, to.Z - from.Z
	local distance = math.sqrt(dx * dx + dz * dz)
	if distance > maxStep then
		return 0
	end
	return distance / dt
end

return Gait
