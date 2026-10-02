--!strict

const popScreen = require(script.popScreen)
const pushScreen = require(script.pushScreen)
const resetScreen = require(script.resetScreen)
const types = require(script.types)
const useScreen = require(script.useScreen)

export type PackageTarget = types.PackageTarget
export type Route = types.Route
export type Screen = types.Screen
export type ScreenName = types.ScreenName

const Navigation = table.freeze({
	popScreen = popScreen,
	pushScreen = pushScreen,
	resetScreen = resetScreen,
	useScreen = useScreen,
})

return Navigation
