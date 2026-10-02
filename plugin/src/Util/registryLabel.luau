--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const types = require(StudioDiscover.Libraries.Core.types)

const LABELS: { [types.Registry]: string } = {
	wally = "Wally",
	pesde = "pesde",
}

-- Returns a registry's name as the user sees it, such as "Wally".
const function registryLabel(registry: types.Registry): string
	return LABELS[registry]
end

return registryLabel
