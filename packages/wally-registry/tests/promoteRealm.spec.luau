--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const promoteRealm = require(ServerScriptService.StudioDiscover.Libraries.WallyRegistry.promoteRealm)

--[[
	This decides whether a package lands in ReplicatedStorage or ServerStorage,
		which is the difference between shipping code to clients and not.
]]
describe("promoteRealm", function()
	it("promotes to shared when either side is shared", function()
		expect(promoteRealm("server", "shared")).toBe("shared")
		expect(promoteRealm("shared", "server")).toBe("shared")
		expect(promoteRealm("shared", "shared")).toBe("shared")
	end)

	it("stays on server only when both sides are server", function()
		expect(promoteRealm("server", "server")).toBe("server")
	end)
end)
