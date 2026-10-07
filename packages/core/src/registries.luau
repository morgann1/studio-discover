--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const types = require(StudioDiscover.Libraries.Core.types)

-- Every registry Discover reads from, in the order the UI lists them.
const registries: { types.Registry } = { "wally", "pesde", "nevermore" }
table.freeze(registries)

return registries
