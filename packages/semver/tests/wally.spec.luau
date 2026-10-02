--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const parseSemver = require(ServerScriptService.StudioDiscover.Libraries.Semver.parseSemver)
const wally = require(ServerScriptService.StudioDiscover.Libraries.Semver.wally)

describe("wally.buildSatisfies", function()
	it("treats a bare version as a caret range", function()
		const satisfies = wally.buildSatisfies("1.2.0")
		expect(satisfies("1.2.0")).toBe(true)
		expect(satisfies("1.9.0")).toBe(true)
		expect(satisfies("2.0.0")).toBe(false)
		expect(satisfies("1.1.0")).toBe(false)
	end)

	it("keeps a 0.x caret range inside the same minor", function()
		const satisfies = wally.buildSatisfies("0.3.1")
		expect(satisfies("0.3.9")).toBe(true)
		expect(satisfies("0.4.0")).toBe(false)
	end)

	it("applies every comma-separated comparator", function()
		const satisfies = wally.buildSatisfies(">=1.0.0, <1.5.0")
		expect(satisfies("1.4.9")).toBe(true)
		expect(satisfies("1.5.0")).toBe(false)
		expect(satisfies("0.9.0")).toBe(false)
	end)
end)

describe("wally.compatible", function()
	it("treats differing 0.x minors as incompatible", function()
		const a = parseSemver("0.1.0")
		const b = parseSemver("0.2.0")
		assert(a ~= nil and b ~= nil, "expected both versions to parse")
		expect(wally.compatible(a, b)).toBe(false)
	end)

	it("treats a shared non-zero major as compatible", function()
		const a = parseSemver("1.1.0")
		const b = parseSemver("1.9.3")
		assert(a ~= nil and b ~= nil, "expected both versions to parse")
		expect(wally.compatible(a, b)).toBe(true)
	end)

	it("treats differing 0.0.x patches as incompatible", function()
		const a = parseSemver("0.0.1")
		const b = parseSemver("0.0.2")
		assert(a ~= nil and b ~= nil, "expected both versions to parse")
		expect(wally.compatible(a, b)).toBe(false)
	end)
end)
