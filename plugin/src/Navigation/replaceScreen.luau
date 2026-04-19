--!strict

local popScreen = require(script.Parent.popScreen)
local pushScreen = require(script.Parent.pushScreen)

local function replaceScreen(name: string, options: { [string]: any }?)
	popScreen()
	pushScreen(name, options)
end

return replaceScreen
