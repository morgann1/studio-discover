--!strict

type Realm = "shared" | "server"

-- Server requests can depend on anything; shared requests can only depend
-- on shared. Mirrors Wally's `Realm::is_dependency_valid`.
local function isDependencyValid(requestRealm: Realm, dependencyRealm: Realm): boolean
	if requestRealm == "server" then
		return true
	end
	return dependencyRealm == "shared"
end

return isDependencyValid
