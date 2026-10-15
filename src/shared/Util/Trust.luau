-- Pure rules for Chapter 3's trust mechanics, shared by the server and specs.
--
--   isAlone      no other teammate within `radius` (The Mimic only catches loners)
--   handshake    two offers count as one handshake if both land within `window`
--   Sequence     the bell puzzle: press signals in order, a wrong one resets

local Trust = {}

function Trust.isAlone(position: Vector3, others: { Vector3 }, radius: number): boolean
	for _, other in others do
		local dx, dz = other.X - position.X, other.Z - position.Z
		if dx * dx + dz * dz <= radius * radius then
			return false
		end
	end
	return true
end

-- offers[a] = { target = b, at = time }. Returns true when b offered to a recently too.
function Trust.handshake(offers, a, b, now: number, window: number): boolean
	local theirs = offers[b]
	return theirs ~= nil and theirs.target == a and now - theirs.at <= window
end

local Sequence = {}
Sequence.__index = Sequence

function Trust.newSequence(answer: { string })
	return setmetatable({ answer = answer, index = 0 }, Sequence)
end

-- Returns "progress", "wrong" (sequence reset) or "done".
function Sequence:Press(id: string): string
	if self.index >= #self.answer then
		return "done"
	end
	if self.answer[self.index + 1] == id then
		self.index += 1
		return if self.index == #self.answer then "done" else "progress"
	end
	-- A wrong signal resets, but it may itself be the right first one.
	self.index = if self.answer[1] == id then 1 else 0
	return "wrong"
end

function Sequence:Progress(): number
	return self.index
end

return Trust
