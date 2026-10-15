-- Pure fear calculation, shared by the server (authoritative) and tests.
-- Inputs describe one player's situation this tick; output is the new fear value.

local FearMath = {}

export type Situation = {
	hasLight: boolean,
	teammatesNear: number,
	creatureDistance: number?, -- nil when no creature is close
	inSafeZone: boolean,
	calmerScares: boolean,
	teamCalmBonus: number?, -- extra recovery from a teammate's lantern
}

function FearMath.step(fear: number, situation: Situation, config, dt: number): number
	local gain = 0
	local recover = 0

	if situation.inSafeZone then
		recover += config.SafeZoneRecover
	else
		if situation.hasLight then
			recover += config.LightRecover
		else
			gain += config.DarknessGain
		end

		if situation.teammatesNear > 0 then
			recover += config.TeammateRecover
		else
			gain += config.AloneGain
		end

		local distance = situation.creatureDistance
		if distance and distance < config.CreatureRadius then
			-- Linear ramp: full gain when touching, nothing at the edge of the radius.
			local closeness = 1 - math.max(distance, 0) / config.CreatureRadius
			gain += config.CreatureNearGain * closeness
		end
	end

	recover += situation.teamCalmBonus or 0

	if situation.calmerScares then
		gain *= config.CalmModeMultiplier
	end

	local nextFear = fear + (gain - recover) * dt
	return math.clamp(nextFear, 0, config.Max)
end

function FearMath.spike(fear: number, amount: number, config, calmerScares: boolean): number
	local scaled = if calmerScares then amount * config.CalmModeMultiplier else amount
	return math.clamp(fear + scaled, 0, config.Max)
end

function FearMath.tier(fear: number, config): string
	if fear >= config.Panicked then
		return "Panicked"
	elseif fear >= config.Scared then
		return "Scared"
	elseif fear >= config.Uneasy then
		return "Uneasy"
	end
	return "Calm"
end

return FearMath
