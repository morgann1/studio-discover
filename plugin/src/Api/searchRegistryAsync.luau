--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const coreTypes = require(StudioDiscover.Libraries.Core.types)
const exhaustiveMatch = require(StudioDiscover.Libraries.Core.exhaustiveMatch)
const searchNevermoreAsync = require(StudioDiscover.Libraries.NevermoreRegistry.Api.searchAsync)
const searchPesdeAsync = require(StudioDiscover.Libraries.PesdeRegistry.Api.searchAsync)
const searchWallyAsync = require(StudioDiscover.Libraries.WallyRegistry.Api.searchAsync)

-- Searches one registry for `query`, or returns nil and why not.
const function searchRegistryAsync(registry: coreTypes.Registry, query: string): ({ coreTypes.PackageBrief }?, string?)
	if registry == "wally" then
		return searchWallyAsync(query)
	elseif registry == "pesde" then
		return searchPesdeAsync(query)
	elseif registry == "nevermore" then
		return searchNevermoreAsync(query)
	end

	return exhaustiveMatch(registry), nil
end

return searchRegistryAsync
