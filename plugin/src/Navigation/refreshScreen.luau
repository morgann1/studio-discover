--!strict

const createScreen = require(script.Parent.createScreen)
const historyAtom = require(script.Parent.historyAtom)

-- Mounts the current screen again under a new id, so it fetches its data again.
const function refreshScreen()
	historyAtom(function(history)
		const stack = table.clone(history.stack)
		stack[#stack] = createScreen(stack[#stack].route)

		return { stack = stack, forward = history.forward }
	end)
end

return refreshScreen
