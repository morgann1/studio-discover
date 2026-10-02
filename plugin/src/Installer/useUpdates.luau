--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const updatesAtom = require(StudioDiscover.Source.Installer.updatesAtom)
const useAtom = require(StudioDiscover.Source.Common.useAtom)
const useInstalledRoots = require(StudioDiscover.Source.Installer.useInstalledRoots)

export type UpdatesState = updatesAtom.UpdatesState

-- Returns the installed roots that have a newer version on their registry.
const function useUpdates(): UpdatesState
	-- Reading the place is what starts the first check.
	useInstalledRoots()

	return useAtom(function()
		return updatesAtom()
	end)
end

return useUpdates
