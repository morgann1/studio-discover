--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const test = JestGlobals.test

const plural = require(ServerScriptService.StudioDiscover.Source.Util.plural)

describe("plural", function()
	test("keeps one singular", function()
		expect(plural(1, "update")).toBe("1 update")
	end)

	test("pluralizes zero and many", function()
		expect(plural(0, "update")).toBe("0 updates")
		expect(plural(3, "update")).toBe("3 updates")
	end)
end)
