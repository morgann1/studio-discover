--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const test = JestGlobals.test

const createUniqueKey = require(ServerScriptService.StudioDiscover.Source.Util.createUniqueKey)

describe("createUniqueKey", function()
	test("suffixes repeats of a name", function()
		const uniqueKey = createUniqueKey()

		expect({ uniqueKey("Dog"), uniqueKey("Dog"), uniqueKey("Dog") }).toEqual({ "Dog", "Dog_2", "Dog_3" })
	end)

	test("never hands out a key twice, even when a name looks like a generated key", function()
		const uniqueKey = createUniqueKey()
		const seen: { [string]: boolean } = {}

		for _, name in { "Dog", "Dog_2", "Dog", "Dog_3", "Dog_3" } do
			const key = uniqueKey(name)
			expect(seen[key]).toBeNil()
			seen[key] = true
		end
	end)
end)
