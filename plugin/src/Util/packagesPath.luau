--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const pesdePackagesFolder = require(StudioDiscover.Libraries.PesdeRegistry.packagesFolder)
const types = require(StudioDiscover.Libraries.Core.types)
const wallyPackagesFolder = require(StudioDiscover.Libraries.WallyRegistry.packagesFolder)

-- Where a registry puts a realm's roots, such as "ReplicatedStorage.Packages".
const function packagesPath(registry: types.Registry, realm: types.Realm): string
	if registry == "pesde" then
		return pesdePackagesFolder.path(realm)
	end

	return wallyPackagesFolder.path(realm)
end

return packagesPath
