--!strict

local types = require(script.Parent.types)

local BASE_SCREEN: types.Screen = table.freeze({
	id = "base",
	name = "base",
	options = table.freeze({}) :: { [string]: any },
})

local function getScreen(screens: { types.Screen }): types.Screen
	return screens[#screens] or BASE_SCREEN
end

return getScreen
