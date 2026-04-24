--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local test = JestGlobals.test

describe("sanity", function()
	test("arithmetic works", function()
		expect(1 + 1).toBe(2)
	end)

	test("string concat works", function()
		expect("foo" .. "bar").toBe("foobar")
	end)
end)
