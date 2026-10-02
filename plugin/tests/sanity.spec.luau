--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const test = JestGlobals.test

describe("sanity", function()
	test("arithmetic works", function()
		expect(1 + 1).toBe(2)
	end)

	test("string concat works", function()
		expect("foo" .. "bar").toBe("foobar")
	end)
end)
