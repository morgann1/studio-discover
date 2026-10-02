--!strict

const createScreen = require(script.Parent.createScreen)
const historyAtom = require(script.Parent.historyAtom)
const types = require(script.Parent.types)

-- Replaces the whole history with one screen, as picking a location in the sidebar does.
const function resetScreen(route: types.Route)
	historyAtom({ stack = { createScreen(route) }, forward = {} })
end

return resetScreen
