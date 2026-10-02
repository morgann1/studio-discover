--!strict

const types = require(script.Parent.types)

const HOME_SCREEN: types.Screen = {
	id = "base",
	route = { name = "Home" },
}

-- Returns the screen on top of the stack, or Home when the stack is empty.
const function getScreen(screens: { types.Screen }): types.Screen
	return screens[#screens] or HOME_SCREEN
end

return getScreen
