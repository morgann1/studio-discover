--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const getScreen = require(script.Parent.getScreen)
const screensAtom = require(script.Parent.screensAtom)
const types = require(script.Parent.types)
const useAtom = require(StudioDiscover.Source.Common.useAtom)

const function useScreen(): types.Screen
	return useAtom(function()
		return getScreen(screensAtom())
	end)
end

return useScreen
