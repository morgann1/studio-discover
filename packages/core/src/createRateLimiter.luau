--!strict

export type RateLimiter = {
	read acquireAsync: () -> (),
}

-- Returns a limiter whose `acquireAsync` yields until `minIntervalSeconds` have passed since the last caller's turn.
const function createRateLimiter(minIntervalSeconds: number): RateLimiter
	local nextAvailableAt = 0

	const function acquireAsync()
		const now = os.clock()
		const reserved = math.max(now, nextAvailableAt)
		nextAvailableAt = reserved + minIntervalSeconds

		const waitSeconds = reserved - now
		if waitSeconds > 0 then
			task.wait(waitSeconds)
		end
	end

	return table.freeze({
		acquireAsync = acquireAsync,
	})
end

return createRateLimiter
