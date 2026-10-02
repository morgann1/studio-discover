--!strict

const HttpService = game:GetService("HttpService")

const types = require(script.Parent.types)

const function createScreen(route: types.Route): types.Screen
	return {
		id = HttpService:GenerateGUID(false),
		route = route,
	}
end

return createScreen
