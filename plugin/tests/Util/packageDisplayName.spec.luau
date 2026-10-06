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

		expect(packageDisplayName("t", settings)).toBe("t")
		expect(packageDisplayName("react-roblox", settings)).toBe("ReactRoblox")
	end)

	test("ignores a rule with an empty display name", function()
		const settings = {
			namingConvention = "PascalCase",
			displayNames = { { name = "t", displayName = "" } },
		}

		expect(packageDisplayName("t", settings)).toBe("T")
	end)
end)
