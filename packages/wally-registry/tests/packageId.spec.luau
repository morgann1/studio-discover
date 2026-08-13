--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local test = JestGlobals.test

local StudioDiscover = ServerScriptService:WaitForChild("StudioDiscover") :: Folder
local packageId = require(StudioDiscover.WallyRegistry.packageId)

describe("packageId.format", function()
	test("joins scope and name with an underscore and the version with an at sign", function()
		expect(packageId.format("evaera", "promise", "4.0.0")).toBe("evaera_promise@4.0.0")
	end)
end)

describe("packageId.parse", function()
	test("round trips a formatted id", function()
		local scope, name, version = packageId.parse(packageId.format("evaera", "promise", "4.0.0"))
		expect(scope).toBe("evaera")
		expect(name).toBe("promise")
		expect(version).toBe("4.0.0")
	end)

	test("keeps a prerelease attached to the version", function()
		local _, _, version = packageId.parse("evaera_promise@4.0.0-rc.1")
		expect(version).toBe("4.0.0-rc.1")
	end)

	test("returns nils for an id with no version", function()
		local scope, name, version = packageId.parse("evaera_promise")
		expect(scope).toBe(nil)
		expect(name).toBe(nil)
		expect(version).toBe(nil)
	end)

	test("returns nils for an id with no scope", function()
		local scope = packageId.parse("promise@4.0.0")
		expect(scope).toBe(nil)
	end)

	-- The split is greedy, so an underscore in the package name lands in the scope.
	-- Wally names cannot contain underscores, so this only matters for malformed ids.
	test("splits on the last underscore when there is more than one", function()
		local scope, name = packageId.parse("my_scope_lib@1.0.0")
		expect(scope).toBe("my_scope")
		expect(name).toBe("lib")
	end)
end)
