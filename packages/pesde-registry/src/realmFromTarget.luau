--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const coreTypes = require(StudioDiscover.Libraries.Core.types)
const types = require(StudioDiscover.Libraries.PesdeRegistry.types)

-- The realm a package published for `target` installs into.
const function realmFromTarget(target: types.Target): coreTypes.Realm
	return if target == "roblox_server" then "server" else "shared"
end

return realmFromTarget
