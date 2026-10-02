--!strict

const createScreen = require(script.Parent.createScreen)
const screensAtom = require(script.Parent.screensAtom)
const types = require(script.Parent.types)

const function pushScreen(route: types.Route)
	const screen = createScreen(route)

	screensAtom(function(stack)
		const nextStack = table.clone(stack)
		table.insert(nextStack, screen)

		return nextStack
	end)
end

return pushScreen
