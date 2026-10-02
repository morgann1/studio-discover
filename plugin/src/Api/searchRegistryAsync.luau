--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const coreTypes = require(StudioDiscover.Libraries.Core.types)
const searchPesdeAsync = require(StudioDiscover.Libraries.PesdeRegistry.Api.searchAsync)
const searchWallyAsync = require(StudioDiscover.Libraries.WallyRegistry.Api.searchAsync)

-- Searches one registry for `query`, or returns nil and why not.
const function searchRegistryAsync(registry: coreTypes.Registry, query: string): ({ coreTypes.PackageBrief }?, string?)
	if registry == "pesde" then
		return searchPesdeAsync(query)
	end

	return searchWallyAsync(query)
end

return searchRegistryAsync
