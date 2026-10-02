--!strict

const createScreen = require(script.Parent.createScreen)
const historyAtom = require(script.Parent.historyAtom)
const types = require(script.Parent.types)

-- Shows a new screen over the current one. Going somewhere new forgets the forward screens.
const function pushScreen(route: types.Route)
	const screen = createScreen(route)

	historyAtom(function(history)
		const stack = table.clone(history.stack)
		table.insert(stack, screen)

		return { stack = stack, forward = {} }
	end)
end

return pushScreen
