--!strict

const createScreen = require(script.Parent.createScreen)
const screensAtom = require(script.Parent.screensAtom)
const types = require(script.Parent.types)

-- Replaces the whole stack with one screen, as the sidebar does.
const function resetScreen(route: types.Route)
	screensAtom({ createScreen(route) })
end

return resetScreen
