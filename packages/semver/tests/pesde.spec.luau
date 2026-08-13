--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local test = JestGlobals.test

local StudioDiscover = ServerScriptService:WaitForChild("StudioDiscover") :: Folder
local pesde = require(StudioDiscover.Semver.pesde)

describe("pesde.normalizeConstraint", function()
	test("drops a caret or tilde prefix", function()
		expect(pesde.normalizeConstraint("^1.2.3")).toBe("1.2.3")
		expect(pesde.normalizeConstraint("~1.2.3")).toBe("1.2.3")
	end)

	test("collapses a wildcard or blank constraint to the empty string", function()
		expect(pesde.normalizeConstraint("*")).toBe("")
		expect(pesde.normalizeConstraint("   ")).toBe("")
	end)
end)

describe("pesde.buildSatisfies", function()
	test("accepts any version for a wildcard constraint", function()
		local satisfies = pesde.buildSatisfies("*")
		expect(satisfies("0.1.0")).toBe(true)
		expect(satisfies("9.9.9")).toBe(true)
	end)

	test("reads a caret constraint as a caret range", function()
		local satisfies = pesde.buildSatisfies("^1.2.0")
		expect(satisfies("1.8.0")).toBe(true)
		expect(satisfies("2.0.0")).toBe(false)
	end)
end)
