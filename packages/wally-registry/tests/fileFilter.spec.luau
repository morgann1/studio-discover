--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local test = JestGlobals.test

local StudioDiscover = ServerScriptService:WaitForChild("StudioDiscover") :: Folder
local buildFileFilter = require(StudioDiscover.WallyRegistry.fileFilter)

describe("the default exclude list", function()
	local keep = buildFileFilter(nil)

	test("keeps ordinary source", function()
		expect(keep("src/init.luau")).toBe(true)
		expect(keep("init.luau")).toBe(true)
	end)

	test("drops dotfiles at any depth", function()
		expect(keep(".gitignore")).toBe(false)
		expect(keep("src/.gitignore")).toBe(false)
	end)

	test("drops any toml, including the manifest", function()
		expect(keep("wally.toml")).toBe(false)
		expect(keep("nested/other.toml")).toBe(false)
	end)

	test("drops the lockfile and the vendored dependency trees", function()
		expect(keep("wally.lock")).toBe(false)
		expect(keep("Packages/Promise.luau")).toBe(false)
		expect(keep("ServerPackages/Thing.luau")).toBe(false)
		expect(keep("DevPackages/Jest.luau")).toBe(false)
		expect(keep("node_modules/pkg/index.js")).toBe(false)
	end)

	test("does not drop a file merely because a name appears mid-path", function()
		expect(keep("src/PackagesHelper.luau")).toBe(true)
	end)
end)

describe("an include list in the manifest", function()
	local manifest = [[
[package]
name = "test/pkg"
version = "1.0.0"

include = ["src", "init.luau"]
]]
	local keep = buildFileFilter(manifest)

	test("keeps only what the list names", function()
		expect(keep("src/main.luau")).toBe(true)
		expect(keep("init.luau")).toBe(true)
		expect(keep("other/main.luau")).toBe(false)
	end)

	-- An include list is authoritative: it replaces the exclude list rather than
	-- being filtered by it, so a listed dotfile survives.
	test("takes precedence over the default excludes", function()
		local keepDotfile = buildFileFilter([=[include = [".darklua.json", "src"]]=])
		expect(keepDotfile(".darklua.json")).toBe(true)
	end)
end)

describe("an exclude list in the manifest", function()
	test("adds to the defaults rather than replacing them", function()
		local keep = buildFileFilter([=[exclude = ["docs"]]=])
		expect(keep("docs/readme.md")).toBe(false)
		expect(keep("wally.toml")).toBe(false)
		expect(keep("src/init.luau")).toBe(true)
	end)
end)
