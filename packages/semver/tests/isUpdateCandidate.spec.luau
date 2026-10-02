--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const isUpdateCandidate = require(ServerScriptService.StudioDiscover.Libraries.Semver.isUpdateCandidate)

describe("isUpdateCandidate", function()
	it("offers a stable root only newer releases", function()
		expect(isUpdateCandidate("1.0.0", "1.5.0")).toBe(true)
		expect(isUpdateCandidate("1.0.0", "2.0.0")).toBe(true)
		expect(isUpdateCandidate("1.0.0", "2.0.0-rc.1")).toBe(false)
		expect(isUpdateCandidate("1.0.0", "0.9.0")).toBe(false)
	end)

	it("offers a prerelease root newer prereleases of its own major.minor.patch", function()
		expect(isUpdateCandidate("0.6.0-rc.1", "0.6.0-rc.6")).toBe(true)
		expect(isUpdateCandidate("0.6.0-rc.1", "0.6.0")).toBe(true)
		expect(isUpdateCandidate("0.6.0-rc.1", "0.7.0")).toBe(true)
		expect(isUpdateCandidate("0.6.0-rc.1", "0.7.0-rc.1")).toBe(false)
	end)
end)
