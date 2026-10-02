--!strict

const getScreen = require(script.Parent.getScreen)
const historyAtom = require(script.Parent.historyAtom)
const types = require(script.Parent.types)

-- Returns the route of the screen shown, for code outside a component.
const function getRoute(): types.Route
	return getScreen(historyAtom()).route
end

return getRoute
