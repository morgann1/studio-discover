--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const test = JestGlobals.test

const parseDependency = require(ServerScriptService.StudioDiscover.Source.Screens.PackageScreen.parseDependency)

describe("parseDependency", function()
	test("splits a spec into scope, name, and range, with the range's version", function()
		expect(parseDependency("evaera/promise@^4.0.0")).toEqual({
			scope = "evaera",
			name = "promise",
			range = "^4.0.0",
			version = "4.0.0",
		})
	end)

	test("keeps a range without a full version, with no version to preselect", function()
		const dependency = parseDependency("sleitnick/comm@1")

		expect(dependency).never.toBeNil()
		expect(dependency and dependency.range).toBe("1")
		expect(dependency and dependency.version).toBeNil()
	end)

	test("rejects a spec without a scope", function()
		expect(parseDependency("promise@^4.0.0")).toBeNil()
	end)
end)
