--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const isDependencyValid = require(ServerScriptService.StudioDiscover.WallyRegistry.isDependencyValid)

-- A shared package replicates to clients, so it cannot reach into ServerStorage.
describe("isDependencyValid", function()
	it("lets a server package depend on either realm", function()
		expect(isDependencyValid("server", "server")).toBe(true)
		expect(isDependencyValid("server", "shared")).toBe(true)
	end)

	it("stops a shared package from depending on a server one", function()
		expect(isDependencyValid("shared", "server")).toBe(false)
	end)

	it("lets a shared package depend on a shared one", function()
		expect(isDependencyValid("shared", "shared")).toBe(true)
	end)
end)
