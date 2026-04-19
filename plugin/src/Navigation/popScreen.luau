--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Cryo = require(StudioDiscover.Packages.Cryo)

local screensAtom = require(script.Parent.screensAtom)

local function popScreen()
	screensAtom(function(stack)
		return Cryo.List.removeIndex(stack, #stack)
	end)
end

return popScreen
