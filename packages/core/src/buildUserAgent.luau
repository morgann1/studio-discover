--!strict

const StudioService = game:GetService("StudioService")

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const version = require(StudioDiscover.Libraries.Core.version)

-- The user agent both registries send, so their maintainers can tell Discover's traffic apart.
const function buildUserAgent(): string
	const userId = StudioService:GetUserId()
	return `StudioDiscover/{version} (+https://github.com/morgann1/studio-discover; uid={userId})`
end

return buildUserAgent
