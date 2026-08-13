--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local createRateLimiter = require(StudioDiscover.Core.createRateLimiter)

return createRateLimiter(1)
