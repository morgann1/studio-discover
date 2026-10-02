--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const test = JestGlobals.test

const routeTitle = require(ServerScriptService.StudioDiscover.Source.Common.Screen.routeTitle)

describe("routeTitle", function()
	test("names a source by its registry", function()
		expect(routeTitle({ name = "Source", registry = "pesde" }, "Original")).toBe("pesde")
	end)

	test("names a package in the user's naming convention", function()
		const route = {
			name = "Package" :: "Package",
			target = { registry = "wally" :: "wally", scope = "roblox", name = "react-roblox" },
		}

		expect(routeTitle(route, "PascalCase")).toBe("ReactRoblox")
		expect(routeTitle(route, "Original")).toBe("react-roblox")
	end)
end)
