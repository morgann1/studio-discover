--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local ReactCharm = require(StudioDiscover.Packages.ReactCharm)

local installerAtom = require(StudioDiscover.Source.Installer.installerAtom)
local types = require(StudioDiscover.Source.Installer.types)

type InstallerState = types.InstallerState

local function useInstaller(): InstallerState
	return ReactCharm.useAtom(installerAtom)
end

return useInstaller
