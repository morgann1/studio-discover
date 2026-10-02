--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const getScreen = require(script.Parent.getScreen)
const historyAtom = require(script.Parent.historyAtom)
const types = require(script.Parent.types)
const useAtom = require(StudioDiscover.Source.Common.useAtom)

const function useScreen(): types.Screen
	return useAtom(function()
		return getScreen(historyAtom())
	end)
end

return useScreen
