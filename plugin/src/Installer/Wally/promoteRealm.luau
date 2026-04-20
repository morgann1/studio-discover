--!strict

type Realm = "shared" | "server"

local function promoteRealm(existing: Realm, incoming: Realm): Realm
	if existing == "shared" or incoming == "shared" then
		return "shared"
	end
	return "server"
end

return promoteRealm
