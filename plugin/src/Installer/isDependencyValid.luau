--!strict

type Realm = "shared" | "server"

local function isDependencyValid(requestRealm: Realm, dependencyRealm: Realm): boolean
	if requestRealm == "server" then
		return true
	end
	return dependencyRealm == "shared"
end

return isDependencyValid
