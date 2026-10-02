--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const installedRootsAtom = require(StudioDiscover.Source.Installer.installedRootsAtom)
const snapshotPesdeRoots = require(StudioDiscover.Libraries.PesdeRegistry.snapshotRoots)
const snapshotRoots = require(StudioDiscover.Libraries.WallyRegistry.snapshotRoots)
const types = require(StudioDiscover.Libraries.Core.types)

-- Reads both registries' roots back out of the place into `installedRootsAtom`.
const function refreshInstalledRoots()
	const installed: { types.InstalledRoot } = {}

	for _, root in snapshotRoots() do
		const installedRoot: types.InstalledRoot = {
			scope = root.scope,
			name = root.name,
			version = root.version,
			realm = root.requestRealm,
			alias = root.alias,
			registry = "wally",
		}
		table.insert(installed, installedRoot)
	end

	for _, root in snapshotPesdeRoots() do
		const installedRoot: types.InstalledRoot = {
			scope = root.scope,
			name = root.name,
			version = root.version,
			realm = root.requestRealm,
			alias = root.alias,
			registry = "pesde",
		}
		table.insert(installed, installedRoot)
	end

	installedRootsAtom(installed)
end

return refreshInstalledRoots
