--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local test = JestGlobals.test

local StudioDiscover = ServerScriptService:WaitForChild("StudioDiscover") :: Folder
local compareSemver = require(StudioDiscover.Semver.compareSemver)
local parseSemver = require(StudioDiscover.Semver.parseSemver)
local wally = require(StudioDiscover.Semver.wally)

local function compare(a: string, b: string): number
	local left = parseSemver(a)
	local right = parseSemver(b)
	assert(left ~= nil and right ~= nil, `unparseable version in {a} / {b}`)
	return compareSemver(left, right)
end

describe("parseSemver", function()
	test("strips a leading v and build metadata", function()
		expect(parseSemver("v1.2.3+build.5")).toEqual({
			major = 1,
			minor = 2,
			patch = 3,
			prerelease = {},
		})
	end)

	test("splits prerelease identifiers, numbering the numeric ones", function()
		local parsed = parseSemver("1.0.0-rc.2")
		assert(parsed ~= nil, "expected 1.0.0-rc.2 to parse")
		local expected: { parseSemver.PrereleaseIdent } = { "rc", 2 }
		expect(parsed.prerelease).toEqual(expected)
	end)

	test("rejects a version that is not three numeric parts", function()
		expect(parseSemver("1.2")).toBe(nil)
	end)
end)

describe("compareSemver", function()
	test("orders by major, then minor, then patch", function()
		expect(compare("2.0.0", "1.9.9")).toBe(1)
		expect(compare("1.2.0", "1.1.9")).toBe(1)
		expect(compare("1.1.2", "1.1.2")).toBe(0)
	end)

	test("sorts a prerelease below its release", function()
		expect(compare("1.0.0-rc.1", "1.0.0")).toBe(-1)
	end)

	test("sorts numeric prerelease identifiers below alphanumeric ones", function()
		expect(compare("1.0.0-1", "1.0.0-alpha")).toBe(-1)
	end)
end)

describe("wally.buildSatisfies", function()
	test("treats a bare version as a caret range", function()
		local satisfies = wally.buildSatisfies("1.2.0")
		expect(satisfies("1.2.0")).toBe(true)
		expect(satisfies("1.9.0")).toBe(true)
		expect(satisfies("2.0.0")).toBe(false)
		expect(satisfies("1.1.0")).toBe(false)
	end)

	test("keeps a 0.x caret range inside the same minor", function()
		local satisfies = wally.buildSatisfies("0.3.1")
		expect(satisfies("0.3.9")).toBe(true)
		expect(satisfies("0.4.0")).toBe(false)
	end)

	test("applies every comma-separated comparator", function()
		local satisfies = wally.buildSatisfies(">=1.0.0, <1.5.0")
		expect(satisfies("1.4.9")).toBe(true)
		expect(satisfies("1.5.0")).toBe(false)
		expect(satisfies("0.9.0")).toBe(false)
	end)
end)

describe("wally.compatible", function()
	test("treats differing 0.x minors as incompatible", function()
		local a = parseSemver("0.1.0")
		local b = parseSemver("0.2.0")
		assert(a ~= nil and b ~= nil, "expected both versions to parse")
		expect(wally.compatible(a, b)).toBe(false)
	end)

	test("treats a shared non-zero major as compatible", function()
		local a = parseSemver("1.1.0")
		local b = parseSemver("1.9.3")
		assert(a ~= nil and b ~= nil, "expected both versions to parse")
		expect(wally.compatible(a, b)).toBe(true)
	end)
end)
