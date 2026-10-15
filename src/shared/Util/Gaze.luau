-- Pure maths for The Hollow One's sweeping gaze (Chapter 4).

local Gaze = {}

-- Is `position` inside the beam? `heading` is the beam's angle in degrees on the
-- XZ plane (0 = +Z, 90 = +X).
function Gaze.inBeam(eye: Vector3, heading: number, halfAngle: number, range: number, position: Vector3): boolean
	local dx, dz = position.X - eye.X, position.Z - eye.Z
	local distance = math.sqrt(dx * dx + dz * dz)
	if distance > range then
		return false
	end
	if distance < 4 then
		return true -- standing at its roots
	end
	local angle = math.deg(math.atan2(dx, dz))
	local difference = (angle - heading + 180) % 360 - 180
	return math.abs(difference) <= halfAngle
end

-- Exposure rises while seen and drains while hidden. Returns the new exposure
-- and whether it reached `limit` (caught).
function Gaze.step(exposure: number, seen: boolean, dt: number, fall: number, limit: number): (number, boolean)
	if seen then
		exposure += dt
	else
		exposure = math.max(0, exposure - fall * dt)
	end
	if exposure >= limit then
		return 0, true
	end
	return exposure, false
end

return Gaze
