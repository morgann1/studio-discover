--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const React = require(StudioDiscover.Packages.React)

const installedRootsAtom = require(StudioDiscover.Source.Installer.installedRootsAtom)
const refreshInstalledRoots = require(StudioDiscover.Source.Installer.refreshInstalledRoots)
const types = require(StudioDiscover.Core.types)
const useAtom = require(StudioDiscover.Source.Common.useAtom)

const NO_ROOTS: { types.InstalledRoot } = {}

export type InstalledRootsState = {
	read roots: { types.InstalledRoot },
	read loading: boolean,
}

-- Returns the installed roots, reading them from the place on first use.
const function useInstalledRoots(): InstalledRootsState
	React.useEffect(function()
		if installedRootsAtom() == nil then
			refreshInstalledRoots()
		end
	end, {})

	const roots = useAtom(function()
		return installedRootsAtom()
	end)
	if roots == nil then
		return { roots = NO_ROOTS, loading = true }
	end

	return { roots = roots, loading = false }
end

return useInstalledRoots
