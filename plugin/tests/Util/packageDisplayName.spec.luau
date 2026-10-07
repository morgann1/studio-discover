--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const test = JestGlobals.test

const packageDisplayName = require(ServerScriptService.StudioDiscover.Source.Util.packageDisplayName)

describe("packageDisplayName", function()
	test("uses the display-name rule over the naming convention", function()
		const settings = {
			namingConvention = "PascalCase",
			displayNames = { { name = "t", displayName = "t" } },
		}

		expect(packageDisplayName("wally", "t", settings)).toBe("t")
		expect(packageDisplayName("wally", "react-roblox", settings)).toBe("ReactRoblox")
	end)

	test("ignores a rule with an empty display name", function()
		const settings = {
			namingConvention = "PascalCase",
			displayNames = { { name = "t", displayName = "" } },
		}

		expect(packageDisplayName("wally", "t", settings)).toBe("T")
	end)

	test("names a Nevermore package by its module, whatever the naming convention", function()
		const settings = {
			namingConvention = "snake_case",
			displayNames = {},
		}

		expect(packageDisplayName("nevermore", "characterutils", settings)).toBe("CharacterUtils")
		expect(packageDisplayName("nevermore", "not-a-known-package", settings)).toBe("not-a-known-package")
	end)

	test("uses the display-name rule over a Nevermore package's known name", function()
		const settings = {
			namingConvention = "Original",
			displayNames = { { name = "maid", displayName = "Janitor" } },
		}

		expect(packageDisplayName("nevermore", "maid", settings)).toBe("Janitor")
	end)
end)
