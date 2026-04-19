--!strict

type Realm = "shared" | "server"

-- Returns the more-restrictive realm: shared dominates server.
-- Matches Wally's "origin realm" climb during resolution: if any shared
-- requester pulls a package, that package is shared.
local function promoteRealm(existing: Realm, incoming: Realm): Realm
	if existing == "shared" or incoming == "shared" then
		return "shared"
	end
	return "server"
end

return promoteRealm
