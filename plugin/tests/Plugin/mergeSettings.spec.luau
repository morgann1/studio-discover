--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const test = JestGlobals.test

const mergeSettings = require(ServerScriptService.StudioDiscover.Source.Plugin.mergeSettings)

const DEFAULTS = table.freeze({ reduceMotion = false, sidebarMode = "Auto" })

const VALIDATORS = {
	reduceMotion = function(value: unknown)
		return typeof(value) == "boolean"
	end,
	sidebarMode = function(value: unknown)
		return value == "Auto" or value == "Compact"
	end,
}

describe("mergeSettings", function()
	test("takes each saved value that passes its validator", function()
		const merged, rejected = mergeSettings(DEFAULTS, { reduceMotion = true, sidebarMode = "Compact" }, VALIDATORS)

		expect(merged).toEqual({ reduceMotion = true, sidebarMode = "Compact" })
		expect(rejected).toEqual({})
	end)

	test("falls back to the default for a corrupt value and reports it", function()
		const merged, rejected = mergeSettings(DEFAULTS, { reduceMotion = "yes", sidebarMode = "Compact" }, VALIDATORS)

		expect(merged).toEqual({ reduceMotion = false, sidebarMode = "Compact" })
		expect(rejected).toEqual({ "reduceMotion" })
	end)

	test("ignores keys it has no validator for", function()
		const merged = mergeSettings(DEFAULTS, { removedSetting = 1 }, VALIDATORS)

		expect(merged).toEqual(DEFAULTS)
	end)

	test("returns the defaults when the saved data is not a table", function()
		const merged = mergeSettings(DEFAULTS, "garbage", VALIDATORS)

		expect(merged).toBe(DEFAULTS)
	end)
end)
