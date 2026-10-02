--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local getScreen = require(script.Parent.getScreen)
local screensAtom = require(script.Parent.screensAtom)
local types = require(script.Parent.types)
local useAtom = require(StudioDiscover.Source.Common.useAtom)

local function useScreen(): types.Screen
	return useAtom(function()
		return getScreen(screensAtom())
	end)
end

return useScreen
