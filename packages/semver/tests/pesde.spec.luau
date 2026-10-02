--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const pesde = require(ServerScriptService.StudioDiscover.Semver.pesde)

describe("pesde.normalizeConstraint", function()
	it("drops a caret or tilde prefix", function()
		expect(pesde.normalizeConstraint("^1.2.3")).toBe("1.2.3")
		expect(pesde.normalizeConstraint("~1.2.3")).toBe("1.2.3")
	end)

	it("collapses a wildcard or blank constraint to the empty string", function()
		expect(pesde.normalizeConstraint("*")).toBe("")
		expect(pesde.normalizeConstraint("   ")).toBe("")
	end)
end)

describe("pesde.buildSatisfies", function()
	it("accepts any version for a wildcard constraint", function()
		const satisfies = pesde.buildSatisfies("*")
		expect(satisfies("0.1.0")).toBe(true)
		expect(satisfies("9.9.9")).toBe(true)
	end)

	it("reads a caret constraint as a caret range", function()
		const satisfies = pesde.buildSatisfies("^1.2.0")
		expect(satisfies("1.8.0")).toBe(true)
		expect(satisfies("2.0.0")).toBe(false)
	end)
end)
