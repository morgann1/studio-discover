--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local test = JestGlobals.test

local StudioDiscover = ServerScriptService:WaitForChild("StudioDiscover") :: Folder
local buildPackageLink = require(StudioDiscover.WallyRegistry.buildPackageLink)

local buildRootPackageLink = buildPackageLink.buildRootPackageLink
local buildSiblingPackageLink = buildPackageLink.buildSiblingPackageLink

local PACKAGE_ID = "evaera_promise@4.0.0"
local MODULE_NAME = "Promise"

--[[
	A link points at the real content under `_Index`. How it gets there depends on
	where the link sits and which realm its target is in, so a wrong branch here
	produces a require that fails only at runtime.
]]

describe("buildSiblingPackageLink", function()
	test("reaches across the shared _Index when both sides are in the same realm", function()
		local build = buildSiblingPackageLink("Promise", PACKAGE_ID, MODULE_NAME, "shared", "shared")
		expect(build.source).toBe(`return require(script.Parent.Parent["{PACKAGE_ID}"]["{MODULE_NAME}"])`)
	end)

	test("reaches into ReplicatedStorage when a server package depends on a shared one", function()
		local build = buildSiblingPackageLink("Promise", PACKAGE_ID, MODULE_NAME, "server", "shared")
		expect(build.source).toBe(
			`return require(game.ReplicatedStorage.Packages._Index["{PACKAGE_ID}"]["{MODULE_NAME}"])`
		)
	end)

	--[[
		A shared package depending on a server one is rejected by
		`isDependencyValid` during resolve, matching wally's
		`Realm::is_dependency_valid`. If it ever reaches apply, resolve is wrong,
		and a link written anyway would put a ServerStorage require behind a
		module that replicates: fine in Studio, broken for every client at
		runtime. Failing the install cancels the recording instead.
	]]
	test("refuses to link a shared package to a server dependency", function()
		expect(function()
			buildSiblingPackageLink("Promise", PACKAGE_ID, MODULE_NAME, "shared", "server")
		end).toThrow()
	end)
end)

describe("buildRootPackageLink", function()
	-- A root is written into the Packages folder of its own realm, so its link
	-- never crosses realms and takes no realm arguments.
	test("descends into _Index from the Packages folder", function()
		local build = buildRootPackageLink("Promise", PACKAGE_ID, MODULE_NAME)
		expect(build.source).toBe(`return require(script.Parent._Index["{PACKAGE_ID}"]["{MODULE_NAME}"])`)
	end)
end)

describe("the built instance", function()
	test("is an unparented ModuleScript named for the alias, with the source left unassigned", function()
		local build = buildSiblingPackageLink("MyAlias", PACKAGE_ID, MODULE_NAME, "shared", "shared")
		expect(build.link:IsA("ModuleScript")).toBe(true)
		expect(build.link.Name).toBe("MyAlias")
		expect(build.link.Parent).toBe(nil)
		-- The caller writes build.source through setScriptSource, never Source directly.
		expect(build.link.Source).toBe("")
	end)
end)
