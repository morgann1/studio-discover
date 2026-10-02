--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const types = require(StudioDiscover.Libraries.Core.types)

-- A package that anything shared needs has to replicate, so shared wins over server.
const function promoteRealm(existing: types.Realm, incoming: types.Realm): types.Realm
	if existing == "shared" or incoming == "shared" then
		return "shared"
	end

	return "server"
end

return promoteRealm
