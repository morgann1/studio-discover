--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local ReactCharm = require(StudioDiscover.Packages.ReactCharm)

local getScreen = require(script.Parent.getScreen)
local screensAtom = require(script.Parent.screensAtom)
local types = require(script.Parent.types)

local function useScreen(): types.Screen
	return ReactCharm.useAtom(function()
		return getScreen(screensAtom())
	end)
end

return useScreen
