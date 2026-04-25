--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local createRateLimiter = require(StudioDiscover.Source.Api.createRateLimiter)

return createRateLimiter(1)
