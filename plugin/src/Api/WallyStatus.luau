--!strict

local Discover = script:FindFirstAncestor("Discover")

local StatusPublisher = require(Discover.Src.Api.StatusPublisher)

export type Status = StatusPublisher.Status

local WallyStatus = {}

WallyStatus.subscribe = StatusPublisher.subscribe
WallyStatus.get = StatusPublisher.get

function WallyStatus.formatWaitMessage(s: Status): string?
	if s.state ~= "waiting" then
		return nil
	end
	local remaining = math.max(0, math.ceil(s.untilClock - os.clock()))
	if s.reason == "rate-limited" then
		return `Rate limited by Wally, retrying in {remaining}s...`
	end
	return `Waiting {remaining}s to respect Wally's rate limit...`
end

return WallyStatus
