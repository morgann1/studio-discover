--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const test = JestGlobals.test

const pickFreeAlias = require(ServerScriptService.StudioDiscover.Source.Installer.pickFreeAlias)

const function takenFrom(aliases: { string }): (string) -> boolean
	return function(candidate)
		return table.find(aliases, candidate) ~= nil
	end
end

describe("pickFreeAlias", function()
	test("keeps an alias nothing else uses", function()
		expect(pickFreeAlias("React", takenFrom({ "Charm" }))).toBe("React")
	end)

	test("numbers the alias from 2 until it is free", function()
		expect(pickFreeAlias("React", takenFrom({ "React", "React2" }))).toBe("React3")
	end)
end)
