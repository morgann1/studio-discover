--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local React = require(StudioDiscover.Packages.React)
local ReactCharm = require(StudioDiscover.Packages.ReactCharm)

local installedRootsAtom = require(StudioDiscover.Source.Installer.installedRootsAtom)
local snapshotRoots = require(StudioDiscover.Source.Installer.snapshotRoots)
local types = require(StudioDiscover.Source.Installer.types)

type InstalledRoot = types.InstalledRoot

-- Reads the current installed-roots list from its atom, lazy-seeding it from
-- disk on first access. Downstream callers get a reactive view that updates
-- whenever `installAsync` refreshes the atom post-commit.
local function useInstalledRoots(): { InstalledRoot }
	React.useEffect(function()
		if installedRootsAtom() ~= nil then
			return
		end
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
	end, {})

	local value = ReactCharm.useAtom(installedRootsAtom)
	return value or {}
end

return useInstalledRoots
