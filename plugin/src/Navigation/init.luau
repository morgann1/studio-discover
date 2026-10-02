--!strict

const getRoute = require(script.getRoute)
const goBack = require(script.goBack)
const goBackTo = require(script.goBackTo)
const goForward = require(script.goForward)
const pushScreen = require(script.pushScreen)
const refreshScreen = require(script.refreshScreen)
const resetScreen = require(script.resetScreen)
const types = require(script.types)
const useHistory = require(script.useHistory)
const useScreen = require(script.useScreen)

export type History = types.History
export type PackageTarget = types.PackageTarget
export type Route = types.Route
export type Screen = types.Screen
export type ScreenName = types.ScreenName

const Navigation = table.freeze({
	getRoute = getRoute,
	goBack = goBack,
	goBackTo = goBackTo,
	goForward = goForward,
	pushScreen = pushScreen,
	refreshScreen = refreshScreen,
	resetScreen = resetScreen,
	useHistory = useHistory,
	useScreen = useScreen,
})

return Navigation
