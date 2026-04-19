--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local React = require(StudioDiscover.Packages.React)
local ReactCharm = require(StudioDiscover.Packages.ReactCharm)

local installedRootsAtom = require(StudioDiscover.Source.Installer.installedRootsAtom)
local refreshInstalledRoots = require(StudioDiscover.Source.Installer.refreshInstalledRoots)
local types = require(StudioDiscover.Source.Installer.types)

type InstalledRoot = types.InstalledRoot

-- Reads the current installed-roots list from its atom, lazy-seeding it from
-- disk on first access. Downstream callers get a reactive view that updates
-- whenever the atom is refreshed post-commit.
local function useInstalledRoots(): { InstalledRoot }
	React.useEffect(function()
		if installedRootsAtom() ~= nil then
			return
		end
		refreshInstalledRoots()
	end, {})

	local value = ReactCharm.useAtom(installedRootsAtom)
	return value or {}
end

return useInstalledRoots
