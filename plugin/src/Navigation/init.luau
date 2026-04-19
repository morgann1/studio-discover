--!strict

local popScreen = require(script.popScreen)
local pushScreen = require(script.pushScreen)
local replaceScreen = require(script.replaceScreen)
local resetScreen = require(script.resetScreen)
local types = require(script.types)
local useScreen = require(script.useScreen)

export type Screen = types.Screen

return table.freeze({
	popScreen = popScreen,
	pushScreen = pushScreen,
	replaceScreen = replaceScreen,
	resetScreen = resetScreen,
	useScreen = useScreen,
})
