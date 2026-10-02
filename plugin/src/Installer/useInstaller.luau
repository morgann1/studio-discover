--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local installerAtom = require(StudioDiscover.Source.Installer.installerAtom)
local types = require(StudioDiscover.Source.Installer.types)
local useAtom = require(StudioDiscover.Source.Common.useAtom)

type InstallerState = types.InstallerState

local function useInstaller(): InstallerState
	return useAtom(installerAtom)
end

return useInstaller
