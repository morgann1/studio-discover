--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local busyAtom = require(StudioDiscover.Source.Installer.busyAtom)
local useAtom = require(StudioDiscover.Source.Common.useAtom)

local function useIsBusy(): boolean
	return useAtom(busyAtom)
end

return useIsBusy
