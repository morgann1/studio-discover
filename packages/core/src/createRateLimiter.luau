--!strict

export type RateLimiter = {
	acquireAsync: () -> (),
}

local function createRateLimiter(minIntervalSeconds: number): RateLimiter
	local nextAvailableAt = 0

	local function acquireAsync()
		local now = os.clock()
		local reserved = math.max(now, nextAvailableAt)
		nextAvailableAt = reserved + minIntervalSeconds

		local wait = reserved - now
		if wait > 0 then
			task.wait(wait)
		end
	end

	return table.freeze({
		acquireAsync = acquireAsync,
	})
end

return createRateLimiter
