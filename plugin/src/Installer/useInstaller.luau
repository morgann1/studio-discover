--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const installerAtom = require(StudioDiscover.Source.Installer.installerAtom)
const types = require(StudioDiscover.Source.Installer.types)
const useAtom = require(StudioDiscover.Source.Common.useAtom)

const function useInstaller(): types.InstallerState
	return useAtom(function()
		return installerAtom()
	end)
end

return useInstaller
