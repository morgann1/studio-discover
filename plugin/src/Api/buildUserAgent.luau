--!strict

local StudioService = game:GetService("StudioService")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Version = require(StudioDiscover.Source.Util.Version)

-- Built per-request so a mid-session sign-in change is reflected.
local function buildUserAgent(): string
	local userId = StudioService:GetUserId()
	return `StudioDiscover/{Version} (+https://github.com/morgann1/studio-discover; user={userId})`
end

return buildUserAgent
