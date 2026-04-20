--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local installedRootsAtom = require(StudioDiscover.Source.Installer.installedRootsAtom)
local snapshotPesdeRoots = require(StudioDiscover.Source.Installer.Pesde.snapshotRoots)
local snapshotRoots = require(StudioDiscover.Source.Installer.Wally.snapshotRoots)
local types = require(StudioDiscover.Source.Installer.types)

type InstalledRoot = types.InstalledRoot

local function refreshInstalledRoots()
	local installed: { InstalledRoot } = {}

	for _, root in snapshotRoots() do
		table.insert(installed, {
			scope = root.scope,
			name = root.name,
			version = root.version,
			realm = root.requestRealm,
			alias = root.alias,
			registry = "wally",
		})
	end

	for _, root in snapshotPesdeRoots() do
		table.insert(installed, {
			scope = root.scope,
			name = root.name,
			version = root.version,
			realm = root.realm,
			alias = root.alias,
			registry = "pesde",
		})
	end

	installedRootsAtom(installed)
end

return refreshInstalledRoots
