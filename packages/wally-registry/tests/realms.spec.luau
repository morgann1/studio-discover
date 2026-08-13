--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local test = JestGlobals.test

local StudioDiscover = ServerScriptService:WaitForChild("StudioDiscover") :: Folder
local isDependencyValid = require(StudioDiscover.WallyRegistry.isDependencyValid)
local promoteRealm = require(StudioDiscover.WallyRegistry.promoteRealm)

--[[
	These two decide whether a package lands in ReplicatedStorage or ServerStorage,
	which is the difference between shipping code to clients and not.
]]

describe("promoteRealm", function()
	test("promotes to shared when either side is shared", function()
		expect(promoteRealm("server", "shared")).toBe("shared")
		expect(promoteRealm("shared", "server")).toBe("shared")
		expect(promoteRealm("shared", "shared")).toBe("shared")
	end)

	test("stays on server only when both sides are server", function()
		expect(promoteRealm("server", "server")).toBe("server")
	end)
end)

describe("isDependencyValid", function()
	test("lets a server package depend on either realm", function()
		expect(isDependencyValid("server", "server")).toBe(true)
		expect(isDependencyValid("server", "shared")).toBe(true)
	end)

	test("stops a shared package from depending on a server one", function()
		expect(isDependencyValid("shared", "server")).toBe(false)
	end)

	test("lets a shared package depend on a shared one", function()
		expect(isDependencyValid("shared", "shared")).toBe(true)
	end)
end)
