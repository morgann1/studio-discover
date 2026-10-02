--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const isNewerVersion = require(ServerScriptService.StudioDiscover.Semver.isNewerVersion)

describe("isNewerVersion", function()
	it("sorts versions newest first by semver, not by text", function()
		const versions = { "0.9.0", "0.10.0", "1.0.0-rc.1", "0.10.1", "1.0.0" }
		table.sort(versions, isNewerVersion)

		expect(versions).toEqual({ "1.0.0", "1.0.0-rc.1", "0.10.1", "0.10.0", "0.9.0" })
	end)

	it("sorts versions that do not parse after every version that does", function()
		const versions = { "latest", "1.0.0", "beta", "0.9.0" }
		table.sort(versions, isNewerVersion)

		expect(versions).toEqual({ "1.0.0", "0.9.0", "latest", "beta" })
	end)
end)
