--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const buildFileFilter = require(ServerScriptService.StudioDiscover.Libraries.WallyRegistry.buildFileFilter)

describe("the default exclude list", function()
	const keep = buildFileFilter(nil)

	it("keeps ordinary source", function()
		expect(keep("src/init.luau")).toBe(true)
		expect(keep("init.luau")).toBe(true)
	end)

	it("drops dotfiles at any depth", function()
		expect(keep(".gitignore")).toBe(false)
		expect(keep("src/.gitignore")).toBe(false)
	end)

	it("drops any toml, including the manifest", function()
		expect(keep("wally.toml")).toBe(false)
		expect(keep("nested/other.toml")).toBe(false)
	end)

	it("drops the lockfile and the vendored dependency trees", function()
		expect(keep("wally.lock")).toBe(false)
		expect(keep("Packages/Promise.luau")).toBe(false)
		expect(keep("ServerPackages/Thing.luau")).toBe(false)
		expect(keep("DevPackages/Jest.luau")).toBe(false)
		expect(keep("node_modules/pkg/index.js")).toBe(false)
	end)

	it("does not drop a file merely because a name appears mid-path", function()
		expect(keep("src/PackagesHelper.luau")).toBe(true)
	end)
end)

describe("an include list in the manifest", function()
	const manifest = [[
[package]
name = "test/pkg"
version = "1.0.0"

include = ["src", "init.luau"]
]]
	const keep = buildFileFilter(manifest)

	it("keeps only what the list names", function()
		expect(keep("src/main.luau")).toBe(true)
		expect(keep("init.luau")).toBe(true)
		expect(keep("other/main.luau")).toBe(false)
	end)

	--[[
		An include list is authoritative: it replaces the exclude list rather than
			being filtered by it, so a listed dotfile survives.
	]]
	it("takes precedence over the default excludes", function()
		const keepDotfile = buildFileFilter([=[include = [".darklua.json", "src"]]=])
		expect(keepDotfile(".darklua.json")).toBe(true)
	end)
end)

describe("an exclude list in the manifest", function()
	it("adds to the defaults rather than replacing them", function()
		const keep = buildFileFilter([=[exclude = ["docs"]]=])
		expect(keep("docs/readme.md")).toBe(false)
		expect(keep("wally.toml")).toBe(false)
		expect(keep("src/init.luau")).toBe(true)
	end)
end)
