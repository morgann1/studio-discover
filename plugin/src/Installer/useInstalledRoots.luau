--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local React = require(StudioDiscover.Packages.React)
local ReactCharm = require(StudioDiscover.Packages.ReactCharm)

local installedRootsAtom = require(StudioDiscover.Source.Installer.installedRootsAtom)
local refreshInstalledRoots = require(StudioDiscover.Source.Installer.refreshInstalledRoots)
local types = require(StudioDiscover.Source.Installer.types)

type InstalledRoot = types.InstalledRoot

export type InstalledRootsState = {
	roots: { InstalledRoot },
	loading: boolean,
}

local function useInstalledRoots(): InstalledRootsState
	React.useEffect(function()
		if installedRootsAtom() ~= nil then
			return
		end
		refreshInstalledRoots()
	end, {})

	local value = ReactCharm.useAtom(installedRootsAtom)
	if value == nil then
		return { roots = {}, loading = true }
	end
	return { roots = value, loading = false }
end

return useInstalledRoots
