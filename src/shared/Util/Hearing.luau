-- Which noise a listener notices. Pure, unit tested in tests/specs/Hearing.spec.luau.
--
-- A noise is { position: Vector3, radius: number, time: number, source: any? }.
-- It can be heard inside its radius; the closer to the source, the more it
-- "matters". Old noises fade after `memory` seconds.

local Hearing = {}

function Hearing.intensity(listener: Vector3, noise, now: number, memory: number, multiplier: number?): number
	local age = now - noise.time
	if age < 0 or age > memory then
		return 0
	end
	local radius = noise.radius * (multiplier or 1)
	local distance = (noise.position - listener).Magnitude
	if distance > radius then
		return 0
	end
	-- Fresher and closer noises win.
	return (1 - distance / radius) * (1 - age / (memory * 2))
end

function Hearing.loudest(listener: Vector3, noises, now: number, memory: number, multiplier: number?)
	local best, bestScore = nil, 0
	for _, noise in noises do
		local score = Hearing.intensity(listener, noise, now, memory, multiplier)
		if score > bestScore then
			best, bestScore = noise, score
		end
	end
	return best, bestScore
end

-- Drops noises older than `memory` seconds, in place.
function Hearing.prune(noises, now: number, memory: number)
	for i = #noises, 1, -1 do
		if now - noises[i].time > memory then
			table.remove(noises, i)
		end
	end
end

return Hearing
