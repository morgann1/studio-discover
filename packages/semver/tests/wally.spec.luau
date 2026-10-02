--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const parseSemver = require(ServerScriptService.StudioDiscover.Libraries.Semver.parseSemver)
const wally = require(ServerScriptService.StudioDiscover.Libraries.Semver.wally)

-- The versions in `versions` that satisfy `constraint`, in order.
const function matching(constraint: string, versions: { string }): { string }
	const satisfies = wally.buildSatisfies(constraint)
	assert(satisfies ~= nil, "expected the constraint to parse")

	const matched = {}
	for _, version in versions do
		if satisfies(version) then
			table.insert(matched, version)
		end
	end

	return matched
end

describe("wally.buildSatisfies", function()
	it("treats a bare version as a caret range", function()
		expect(matching("1.2.0", { "1.1.0", "1.2.0", "1.9.0", "2.0.0" })).toEqual({ "1.2.0", "1.9.0" })
	end)

	it("keeps a 0.x caret range inside the same minor", function()
		expect(matching("0.3.1", { "0.3.9", "0.4.0" })).toEqual({ "0.3.9" })
	end)

	it("applies every comma-separated comparator", function()
		expect(matching(">=1.0.0, <1.5.0", { "0.9.0", "1.4.9", "1.5.0" })).toEqual({ "1.4.9" })
	end)

	it("matches a version that satisfies any alternative joined by ||", function()
		const versions = { "0.9.9", "1.0.0", "1.9.9", "2.0.0", "2.5.0", "3.0.0", "3.9.9", "4.0.0" }
		expect(matching(">=1.0.0, <2.0.0 || >=3.0.0, <4.0.0", versions)).toEqual({ "1.0.0", "1.9.9", "3.0.0", "3.9.9" })
	end)

	it("matches a prerelease only when a comparator names one on the same major.minor.patch", function()
		expect(matching(">=1.0.0, <2.0.0", { "1.5.0", "1.5.0-rc.1", "2.0.0-rc.1" })).toEqual({ "1.5.0" })
		expect(matching(">=2.0.0-rc.1", { "2.0.0-rc.2", "2.0.1-rc.1" })).toEqual({ "2.0.0-rc.2" })
		expect(matching(">=0.6.0-rc.1, <0.7.0", { "0.6.0-rc.6", "0.6.0", "0.7.0-rc.1" })).toEqual({
			"0.6.0-rc.6",
			"0.6.0",
		})
	end)

	it("rejects a prerelease for Wally's *, which arrives as >=0.0.0", function()
		expect(matching(">=0.0.0", { "0.1.0", "2.0.0-rc.1" })).toEqual({ "0.1.0" })
	end)

	it("applies the prerelease rule within each alternative joined by ||", function()
		expect(matching(">=1.0.0, <3.0.0 || =2.0.0-rc.1", { "2.0.0-rc.1", "2.0.0-rc.2" })).toEqual({ "2.0.0-rc.1" })
	end)

	it("fails a constraint that does not parse instead of matching everything", function()
		expect(wally.buildSatisfies("not a version")).toBe(nil)
		expect(wally.buildSatisfies(">=1.0.0 || banana")).toBe(nil)
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
