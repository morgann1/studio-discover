--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local test = JestGlobals.test

local StudioDiscover = ServerScriptService:WaitForChild("StudioDiscover") :: Folder
local packageId = require(StudioDiscover.PesdeRegistry.packageId)

--[[
	pesde ids carry a target as well as a version, because the same package can be
	published for roblox and roblox_server and the two resolve independently.
]]

describe("packageId.format", function()
	test("keeps the scope separator, and puts the target after the version", function()
		expect(packageId.format("pesde", "hello", "1.0.0", "roblox")).toBe("pesde/hello@1.0.0 roblox")
		expect(packageId.format("pesde", "hello", "1.0.0", "roblox_server")).toBe("pesde/hello@1.0.0 roblox_server")
	end)
end)

describe("packageId.parse", function()
	test("round trips a formatted id", function()
		local scope, name, version, target = packageId.parse(packageId.format("pesde", "hello", "1.0.0", "roblox"))
		expect(scope).toBe("pesde")
		expect(name).toBe("hello")
		expect(version).toBe("1.0.0")
		expect(target).toBe("roblox")
	end)

	test("distinguishes the two roblox targets", function()
		local _, _, _, target = packageId.parse("pesde/hello@1.0.0 roblox_server")
		expect(target).toBe("roblox_server")
	end)

	test("returns nils when the target is missing", function()
		local scope = packageId.parse("pesde/hello@1.0.0")
		expect(scope).toBe(nil)
	end)

	test("returns nils when the scope is missing", function()
		local scope = packageId.parse("hello@1.0.0 roblox")
		expect(scope).toBe(nil)
	end)

	test("returns nils for an id with no version", function()
		local scope = packageId.parse("pesde/hello")
		expect(scope).toBe(nil)
	end)
end)
