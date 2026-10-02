--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const isBreakingUpdate = require(ServerScriptService.StudioDiscover.Libraries.Semver.isBreakingUpdate)

describe("isBreakingUpdate", function()
	it("is breaking when the major version changes", function()
		expect(isBreakingUpdate("3.2.1", "4.0.0")).toBe(true)
		expect(isBreakingUpdate("1.2.0", "1.9.3")).toBe(false)
	end)

	it("treats a minor change below 1.0.0 as breaking, like a caret range does", function()
		expect(isBreakingUpdate("0.9.0", "0.10.0")).toBe(true)
		expect(isBreakingUpdate("0.10.0", "0.10.4")).toBe(false)
		expect(isBreakingUpdate("0.0.3", "0.0.4")).toBe(true)
	end)

	it("is never breaking for a version that does not parse", function()
		expect(isBreakingUpdate("latest", "2.0.0")).toBe(false)
	end)
end)
