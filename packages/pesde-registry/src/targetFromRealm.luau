--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const coreTypes = require(StudioDiscover.Core.types)
const types = require(StudioDiscover.PesdeRegistry.types)

-- The pesde target a package installs from for each realm.
const function targetFromRealm(realm: coreTypes.Realm): types.Target
	return if realm == "server" then "roblox_server" else "roblox"
end

return targetFromRealm
