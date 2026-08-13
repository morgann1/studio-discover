--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local test = JestGlobals.test

local StudioDiscover = ServerScriptService:WaitForChild("StudioDiscover") :: Folder
local containerName = require(StudioDiscover.PesdeRegistry.containerName)

--[[
	pesde and its wally-proxied packages sit in the same index, under different
	naming rules: pesde entries are versionless, wally entries carry the version.
]]

describe("containerName", function()
	test("names a pesde container with a plus and no version", function()
		expect(containerName.formatPesdeName("pesde", "hello")).toBe("pesde+hello")
	end)

	test("names a wally container the way wally does, with the version", function()
		expect(containerName.formatWallyName("evaera", "promise", "4.0.0")).toBe("evaera_promise@4.0.0")
	end)

	test("picks the naming rule from the kind", function()
		expect(containerName.formatOuter("pesde", "pesde", "hello", "1.0.0")).toBe("pesde+hello")
		expect(containerName.formatOuter("wally", "evaera", "promise", "4.0.0")).toBe("evaera_promise@4.0.0")
	end)
end)
