--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const exhaustiveMatch = require(StudioDiscover.Libraries.Core.exhaustiveMatch)
const nevermoreGameFolder = require(StudioDiscover.Libraries.NevermoreRegistry.gameFolder)
const pesdePackagesFolder = require(StudioDiscover.Libraries.PesdeRegistry.packagesFolder)
const types = require(StudioDiscover.Libraries.Core.types)
const wallyPackagesFolder = require(StudioDiscover.Libraries.WallyRegistry.packagesFolder)

--[[
	Where a registry puts a realm's roots, such as "ReplicatedStorage.Packages".
		Nevermore keeps every package in one `node_modules`, whatever the realm.
]]
const function packagesPath(registry: types.Registry, realm: types.Realm): string
	if registry == "wally" then
		return wallyPackagesFolder.path(realm)
	elseif registry == "pesde" then
		return pesdePackagesFolder.path(realm)
	elseif registry == "nevermore" then
		return nevermoreGameFolder.PATH
	end

	return exhaustiveMatch(registry)
end

return packagesPath
