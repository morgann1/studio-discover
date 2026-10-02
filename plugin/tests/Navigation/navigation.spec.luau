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
const popScreen = require(NavigationFolder.popScreen)
const pushScreen = require(NavigationFolder.pushScreen)
const resetScreen = require(NavigationFolder.resetScreen)
const screensAtom = require(NavigationFolder.screensAtom)

const function currentRouteName(): string
	return getScreen(screensAtom()).route.name
end

beforeEach(function()
	screensAtom({})
end)

describe("navigation", function()
	test("shows Home when nothing has been pushed, and after popping the last screen", function()
		expect(currentRouteName()).toBe("Home")

		pushScreen({ name = "Settings" })
		popScreen()
		popScreen()

		expect(currentRouteName()).toBe("Home")
	end)

	test("shows the last pushed screen, and the one under it after a pop", function()
		pushScreen({ name = "Settings" })
		pushScreen({ name = "Registries" })
		expect(currentRouteName()).toBe("Registries")

		popScreen()
		expect(currentRouteName()).toBe("Settings")
	end)

	test("replaces the stack instead of mutating it, so subscribers see a change", function()
		pushScreen({ name = "Settings" })
		const before = screensAtom()

		pushScreen({ name = "Registries" })

		expect(screensAtom()).never.toBe(before)
		expect(#before).toBe(1)
	end)

	test("reset leaves only the new screen", function()
		pushScreen({ name = "Settings" })
		pushScreen({ name = "Registries" })
		resetScreen({ name = "Manage" })

		expect(#screensAtom()).toBe(1)
		expect(currentRouteName()).toBe("Manage")
	end)
end)
