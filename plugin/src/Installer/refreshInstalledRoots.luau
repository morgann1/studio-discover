--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local installedRootsAtom = require(StudioDiscover.Source.Installer.installedRootsAtom)
local snapshotRoots = require(StudioDiscover.Source.Installer.snapshotRoots)
local types = require(StudioDiscover.Source.Installer.types)

type InstalledRoot = types.InstalledRoot

-- Re-reads the top-level alias links from disk and publishes them on the
-- installed-roots atom so every `useInstalledRoots()` consumer repaints.
local function refreshInstalledRoots()
	local roots = snapshotRoots()
	local installed: { InstalledRoot } = {}
	for _, root in roots do
		table.insert(installed, {
			scope = root.scope,
			name = root.name,
			version = root.version,
			realm = root.requestRealm,
			alias = root.alias,
		})
	end
	installedRootsAtom(installed)
end

return refreshInstalledRoots
