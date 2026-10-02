--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const types = require(StudioDiscover.Libraries.Core.types)

--[[
	Whether a package in `requestRealm` may depend on one in `dependencyRealm`.
		Matches wally's `Realm::is_dependency_valid`: a shared package cannot reach
		into the server.
]]
const function isDependencyValid(requestRealm: types.Realm, dependencyRealm: types.Realm): boolean
	if requestRealm == "server" then
		return true
	end

	return dependencyRealm == "shared"
end

return isDependencyValid
