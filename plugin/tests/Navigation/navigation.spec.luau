--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const beforeEach = JestGlobals.beforeEach
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const test = JestGlobals.test

const NavigationFolder = ServerScriptService.StudioDiscover.Source.Navigation
const getScreen = require(NavigationFolder.getScreen)
const goBack = require(NavigationFolder.goBack)
const goBackTo = require(NavigationFolder.goBackTo)
const goForward = require(NavigationFolder.goForward)
const historyAtom = require(NavigationFolder.historyAtom)
const pushScreen = require(NavigationFolder.pushScreen)
const refreshScreen = require(NavigationFolder.refreshScreen)
const resetScreen = require(NavigationFolder.resetScreen)

const function currentRouteName(): string
	return getScreen(historyAtom()).route.name
end

beforeEach(function()
	resetScreen({ name = "Installed" })
end)

describe("navigation", function()
	test("going back stops at the last screen", function()
		pushScreen({ name = "Settings" })
		goBack()
		goBack()

		expect(currentRouteName()).toBe("Installed")
		expect(#historyAtom().stack).toBe(1)
	end)

	test("going forward returns to the screen going back left", function()
		pushScreen({ name = "Settings" })
		pushScreen({ name = "DisplayNames" })
		goBack()
		goBack()
		expect(currentRouteName()).toBe("Installed")

		goForward()
		expect(currentRouteName()).toBe("Settings")

		goForward()
		expect(currentRouteName()).toBe("DisplayNames")
	end)

	test("pushing a new screen forgets the forward screens", function()
		pushScreen({ name = "Settings" })
		goBack()
		pushScreen({ name = "Search" })
		goForward()

		expect(currentRouteName()).toBe("Search")
	end)

	test("going back to a screen pops everything above it, and forward walks back up in order", function()
		const base = getScreen(historyAtom())
		pushScreen({ name = "Source", registry = "wally" })
		pushScreen({ name = "Settings" })
		pushScreen({ name = "DisplayNames" })

		goBackTo(base.id)
		expect(currentRouteName()).toBe("Installed")

		goForward()
		expect(currentRouteName()).toBe("Source")

		goForward()
		expect(currentRouteName()).toBe("Settings")
	end)

	test("refreshing mounts the same route under a new id", function()
		const before = getScreen(historyAtom())
		refreshScreen()
		const after = getScreen(historyAtom())

		expect(after.route).toBe(before.route)
		expect(after.id).never.toBe(before.id)
	end)

	test("reset leaves only the new screen and nothing to go forward to", function()
		pushScreen({ name = "Settings" })
		goBack()
		resetScreen({ name = "Updates" })
		goForward()

		expect(#historyAtom().stack).toBe(1)
		expect(currentRouteName()).toBe("Updates")
	end)
end)
