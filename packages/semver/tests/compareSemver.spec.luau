--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const compareSemver = require(ServerScriptService.StudioDiscover.Semver.compareSemver)
const parseSemver = require(ServerScriptService.StudioDiscover.Semver.parseSemver)

const function compare(a: string, b: string): number
	const left = parseSemver(a)
	const right = parseSemver(b)
	assert(left ~= nil and right ~= nil, "expected both versions to parse")

	return compareSemver(left, right)
end

describe("compareSemver", function()
	it("orders by major, then minor, then patch", function()
		expect(compare("2.0.0", "1.9.9")).toBe(1)
		expect(compare("1.2.0", "1.1.9")).toBe(1)
		expect(compare("1.1.2", "1.1.2")).toBe(0)
	end)

	it("sorts a prerelease below its release", function()
		expect(compare("1.0.0-rc.1", "1.0.0")).toBe(-1)
	end)

	it("sorts numeric prerelease identifiers below alphanumeric ones", function()
		expect(compare("1.0.0-1", "1.0.0-alpha")).toBe(-1)
	end)
end)
