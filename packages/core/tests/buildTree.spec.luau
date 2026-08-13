--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local test = JestGlobals.test

local StudioDiscover = ServerScriptService:WaitForChild("StudioDiscover") :: Folder
local buildTree = require(StudioDiscover.Core.buildTree)
local classifyFile = require(StudioDiscover.Core.classifyFile)

-- Archives arrive with everything under one top-level directory, which buildTree drops.
local function entry(path: string, content: string?): buildTree.Entry
	return { path = path, content = content or "return nil" }
end

describe("classifyFile", function()
	test("maps a file suffix to the class of script it becomes", function()
		expect(classifyFile("pkg/init.server.luau")).toBe("Script")
		expect(classifyFile("pkg/main.client.lua")).toBe("LocalScript")
		expect(classifyFile("pkg/util.luau")).toBe("ModuleScript")
	end)

	test("skips anything that is not Luau source", function()
		expect(classifyFile("pkg/README.md")).toBe("skip")
		expect(classifyFile("pkg/default.project.json")).toBe("skip")
	end)
end)

describe("buildTree", function()
	test("drops the archive's top-level directory and keeps the rest", function()
		local root = buildTree({ entry("archive-root/nested/thing.luau") }, "Pkg")
		expect(root.Name).toBe("Pkg")
		local nested = root:FindFirstChild("nested")
		expect(nested).never.toBeNil()
		expect((nested :: Instance):FindFirstChild("thing")).never.toBeNil()
	end)

	test("promotes a folder's init file into a ModuleScript named for the folder", function()
		local root = buildTree({
			entry("archive-root/Sub/init.luau"),
			entry("archive-root/Sub/helper.luau"),
		}, "Pkg")

		local sub = root:FindFirstChild("Sub")
		expect(sub).never.toBeNil()
		expect((sub :: Instance):IsA("ModuleScript")).toBe(true)
		expect((sub :: Instance):FindFirstChild("helper")).never.toBeNil()
	end)

	test("promotes a root init file into the package root itself", function()
		local root = buildTree({
			entry("archive-root/init.luau"),
			entry("archive-root/helper.luau"),
		}, "Pkg")

		expect(root:IsA("ModuleScript")).toBe(true)
		expect(root.Name).toBe("Pkg")
		expect(root:FindFirstChild("helper")).never.toBeNil()
	end)

	test("returns sources as pending rather than assigning them", function()
		local _, pending = buildTree({ entry("archive-root/thing.luau", "return 42") }, "Pkg")
		expect(#pending).toBe(1)
		expect(pending[1].content).toBe("return 42")
		expect(pending[1].script:IsA("ModuleScript")).toBe(true)
	end)

	test("leaves non-Luau files out of the tree", function()
		local root, pending = buildTree({
			entry("archive-root/thing.luau"),
			entry("archive-root/README.md"),
		}, "Pkg")

		expect(#root:GetChildren()).toBe(1)
		expect(#pending).toBe(1)
	end)
end)
