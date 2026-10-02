--!strict

const types = require(script.Parent.types)

-- Returns the screen on top of the stack, the one shown.
const function getScreen(history: types.History): types.Screen
	return history.stack[#history.stack]
end

return getScreen
