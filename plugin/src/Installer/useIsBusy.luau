--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local ReactCharm = require(StudioDiscover.Packages.ReactCharm)

local busyAtom = require(StudioDiscover.Source.Installer.busyAtom)

local function useIsBusy(): boolean
	return ReactCharm.useAtom(busyAtom)
end

return useIsBusy
