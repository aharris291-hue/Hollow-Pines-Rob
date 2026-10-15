-- Per-key cooldown used to stop clients spamming remotes.

local RateLimit = {}
RateLimit.__index = RateLimit

function RateLimit.new(cooldown: number, clock: (() -> number)?)
	return setmetatable({ cooldown = cooldown, last = {}, clock = clock or os.clock }, RateLimit)
end

function RateLimit:Allow(key): boolean
	local now = self.clock()
	local last = self.last[key]
	if last and now - last < self.cooldown then
		return false
	end
	self.last[key] = now
	return true
end

function RateLimit:Forget(key)
	self.last[key] = nil
end

return RateLimit
