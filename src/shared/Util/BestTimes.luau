-- Pure helpers for fastest-escape times: personal bests saved in the profile
-- (BestTimes, keyed by chapter id as a string) and the lobby leaderboards.

local BestTimes = {}

local MAX_SECONDS = 24 * 60 * 60

-- Leaderboards store whole seconds; anything outside a sane range is rejected.
function BestTimes.sanitize(seconds: number): number?
	if type(seconds) ~= "number" or seconds ~= seconds then
		return nil
	end
	local whole = math.floor(seconds)
	if whole < 1 or whole > MAX_SECONDS then
		return nil
	end
	return whole
end

-- Is `seconds` a new personal best compared with the saved `previous` (nil or 0
-- means no time yet)?
function BestTimes.isBetter(previous: number?, seconds: number): boolean
	return previous == nil or previous <= 0 or seconds < previous
end

-- "4:05", or "1:02:03" past an hour.
function BestTimes.format(seconds: number): string
	local whole = math.max(0, math.floor(seconds))
	local hours, minutes, secs = whole // 3600, (whole % 3600) // 60, whole % 60
	if hours > 0 then
		return string.format("%d:%02d:%02d", hours, minutes, secs)
	end
	return string.format("%d:%02d", minutes, secs)
end

-- The board's lines: "1. Name  4:05", fastest first, at most `limit`.
export type Entry = { name: string, seconds: number }

function BestTimes.lines(entries: { Entry }, limit: number): { string }
	local sorted = table.clone(entries)
	table.sort(sorted, function(a, b)
		if a.seconds == b.seconds then
			return a.name < b.name
		end
		return a.seconds < b.seconds
	end)
	local lines = {}
	for rank = 1, math.min(limit, #sorted) do
		local entry = sorted[rank]
		table.insert(lines, string.format("%d. %s  %s", rank, entry.name, BestTimes.format(entry.seconds)))
	end
	return lines
end

return BestTimes
