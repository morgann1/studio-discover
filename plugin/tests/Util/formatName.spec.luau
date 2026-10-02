--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const test = JestGlobals.test

const formatName = require(ServerScriptService.StudioDiscover.Source.Util.formatName)

describe("formatName", function()
	test("leaves the name alone for Original", function()
		expect(formatName("react-roblox", "Original")).toBe("react-roblox")
	end)

	test("splits at dashes, underscores, and case changes", function()
		expect(formatName("react-roblox", "PascalCase")).toBe("ReactRoblox")
		expect(formatName("react_roblox", "camelCase")).toBe("reactRoblox")
		expect(formatName("ReactRoblox", "snake_case")).toBe("react_roblox")
		expect(formatName("reactRoblox", "kebab-case")).toBe("react-roblox")
	end)
end)
