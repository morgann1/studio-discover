--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const types = require(StudioDiscover.Libraries.Core.types)

-- Every realm a package can install into, for code that visits each one.
const realms: { types.Realm } = { "shared", "server" }
table.freeze(realms)

return realms
