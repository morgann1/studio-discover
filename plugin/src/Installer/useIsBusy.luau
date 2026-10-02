--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const busyAtom = require(StudioDiscover.Source.Installer.busyAtom)
const useAtom = require(StudioDiscover.Source.Common.useAtom)

const function useIsBusy(): boolean
	return useAtom(function()
		return busyAtom()
	end)
end

return useIsBusy
