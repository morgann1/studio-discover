--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const historyAtom = require(script.Parent.historyAtom)
const types = require(script.Parent.types)
const useAtom = require(StudioDiscover.Source.Common.useAtom)

const function useHistory(): types.History
	return useAtom(function()
		return historyAtom()
	end)
end

return useHistory
