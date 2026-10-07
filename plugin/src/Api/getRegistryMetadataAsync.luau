--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const coreTypes = require(StudioDiscover.Libraries.Core.types)
const exhaustiveMatch = require(StudioDiscover.Libraries.Core.exhaustiveMatch)
const getNevermoreMetadataAsync = require(StudioDiscover.Libraries.NevermoreRegistry.Api.getMetadataAsync)
const getPesdeMetadataAsync = require(StudioDiscover.Libraries.PesdeRegistry.Api.getMetadataAsync)
const getWallyMetadataAsync = require(StudioDiscover.Libraries.WallyRegistry.Api.getMetadataAsync)

-- Fetches a package's metadata from one registry, or returns nil and why not.
const function getRegistryMetadataAsync(
	registry: coreTypes.Registry,
	scope: string,
	name: string
): (coreTypes.PackageMetadata?, string?)
	if registry == "wally" then
		return getWallyMetadataAsync(scope, name)
	elseif registry == "pesde" then
		return getPesdeMetadataAsync(scope, name)
	elseif registry == "nevermore" then
		return getNevermoreMetadataAsync(scope, name)
	end

	return exhaustiveMatch(registry), nil
end

return getRegistryMetadataAsync
