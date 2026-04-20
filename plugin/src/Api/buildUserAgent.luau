--!strict

local StudioService = game:GetService("StudioService")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Version = require(StudioDiscover.Source.Util.Version)

local function buildUserAgent(): string
	local userId = StudioService:GetUserId()
	return `StudioDiscover/{Version} (+https://github.com/morgann1/studio-discover; user={userId})`
end

return buildUserAgent
