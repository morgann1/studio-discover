--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const parseSemver = require(ServerScriptService.StudioDiscover.Libraries.Semver.parseSemver)

describe("parseSemver", function()
	it("strips a leading v and build metadata", function()
		expect(parseSemver("v1.2.3+build.5")).toEqual({
			major = 1,
			minor = 2,
			patch = 3,
			prerelease = {},
		})
	end)

	it("splits prerelease identifiers, numbering the numeric ones", function()
		const parsed = parseSemver("1.0.0-rc.2")
		assert(parsed ~= nil, "expected 1.0.0-rc.2 to parse")

		const expected: { parseSemver.PrereleaseIdent } = { "rc", 2 }
		expect(parsed.prerelease).toEqual(expected)
	end)

	it("rejects a version that is not three numeric parts", function()
		expect(parseSemver("1.2")).toBe(nil)
	end)
end)
