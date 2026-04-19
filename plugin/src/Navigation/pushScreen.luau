--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Cryo = require(StudioDiscover.Packages.Cryo)

local createScreenId = require(script.Parent.createScreenId)
local screensAtom = require(script.Parent.screensAtom)
local types = require(script.Parent.types)

local function pushScreen(name: string, options: { [string]: any }?)
	local screen: types.Screen = {
		id = createScreenId(),
		name = name,
		options = options or {},
	}

	screensAtom(function(stack)
		return Cryo.List.join(stack, { screen })
	end)
end

return pushScreen
