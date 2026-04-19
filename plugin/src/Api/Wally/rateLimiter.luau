--!strict

-- Wally's public API policy requires at most 1 request per second:
-- https://wally.run/policies
local MIN_INTERVAL_SECONDS = 1

local nextAvailableAt = 0

-- Reserves the next 1s slot atomically before yielding, so concurrent callers
-- serialize instead of both taking the current slot.
local function acquireAsync()
	local now = os.clock()
	local reserved = math.max(now, nextAvailableAt)
	nextAvailableAt = reserved + MIN_INTERVAL_SECONDS

	local wait = reserved - now
	if wait > 0 then
		task.wait(wait)
	end
end

return table.freeze({
	acquireAsync = acquireAsync,
})
