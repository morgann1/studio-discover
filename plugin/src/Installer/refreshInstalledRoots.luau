--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const exhaustiveMatch = require(StudioDiscover.Libraries.Core.exhaustiveMatch)
const installedRootsAtom = require(StudioDiscover.Source.Installer.installedRootsAtom)
const registries = require(StudioDiscover.Libraries.Core.registries)
const snapshotNevermoreRoots = require(StudioDiscover.Libraries.NevermoreRegistry.snapshotRoots)
const snapshotPesdeRoots = require(StudioDiscover.Libraries.PesdeRegistry.snapshotRoots)
const snapshotWallyRoots = require(StudioDiscover.Libraries.WallyRegistry.snapshotRoots)
const types = require(StudioDiscover.Libraries.Core.types)

const function snapshotRoots(registry: types.Registry): { types.RootRequest }
	if registry == "wally" then
		return snapshotWallyRoots()
	elseif registry == "pesde" then
		return snapshotPesdeRoots()
	elseif registry == "nevermore" then
		return snapshotNevermoreRoots()
	end

	return exhaustiveMatch(registry)
end

-- Reads every registry's roots back out of the place into `installedRootsAtom`.
const function refreshInstalledRoots()
	const installed: { types.InstalledRoot } = {}

	for _, registry in registries do
		for _, root in snapshotRoots(registry) do
			const installedRoot: types.InstalledRoot = {
				scope = root.scope,
				name = root.name,
				version = root.version,
				realm = root.requestRealm,
				alias = root.alias,
				registry = registry,
			}
			table.insert(installed, installedRoot)
		end
	end

	installedRootsAtom(installed)
end

return refreshInstalledRoots
