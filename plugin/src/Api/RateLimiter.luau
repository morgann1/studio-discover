--!strict

local Discover = script:FindFirstAncestor("Discover")

local StatusPublisher = require(Discover.Src.Api.StatusPublisher)

local MIN_INTERVAL = 1.05

local nextSlotClock = 0

local RateLimiter = {}

function RateLimiter.acquireSlotAsync()
	local now = os.clock()
	local mySlot = if nextSlotClock > now then nextSlotClock else now
	nextSlotClock = mySlot + MIN_INTERVAL
	local waitSeconds = mySlot - now
	if waitSeconds > 0 then
		StatusPublisher.set({ state = "waiting", reason = "queue", untilClock = mySlot })
		task.wait(waitSeconds)
		StatusPublisher.clearIfElapsed(mySlot)
	end
end

function RateLimiter.backoffAsync(seconds: number?)
	local waitSeconds = seconds or MIN_INTERVAL
	local untilClock = os.clock() + waitSeconds
	if untilClock > nextSlotClock then
		nextSlotClock = untilClock
	end
	StatusPublisher.set({ state = "waiting", reason = "rate-limited", untilClock = untilClock })
	task.wait(waitSeconds)
	StatusPublisher.clearIfElapsed(untilClock)
end

return RateLimiter
