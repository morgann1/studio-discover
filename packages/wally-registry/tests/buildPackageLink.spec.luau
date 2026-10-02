--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const buildPackageLink = require(ServerScriptService.StudioDiscover.Libraries.WallyRegistry.buildPackageLink)

const buildRootPackageLink = buildPackageLink.buildRootPackageLink
const buildSiblingPackageLink = buildPackageLink.buildSiblingPackageLink

const PACKAGE_ID = "evaera_promise@4.0.0"
const MODULE_NAME = "Promise"

--[[
	A link points at the real content under `_Index`. How it gets there depends on
		where the link sits and which realm its target is in, so a wrong branch here
		produces a require that fails only at runtime.
]]
describe("buildSiblingPackageLink", function()
	it("returns an unparented ModuleScript named for the alias", function()
		const build = buildSiblingPackageLink("MyAlias", PACKAGE_ID, MODULE_NAME, "shared", "shared")
		expect(build.link:IsA("ModuleScript")).toBe(true)
		expect(build.link.Name).toBe("MyAlias")
		expect(build.link.Parent).toBe(nil)
	end)

	it("requires the package beside it when both sides are in the same realm", function()
		const build = buildSiblingPackageLink("Promise", PACKAGE_ID, MODULE_NAME, "shared", "shared")
		expect(build.source).toBe(`return require(script.Parent.Parent["{PACKAGE_ID}"]["{MODULE_NAME}"])`)
	end)

	it("reaches into ReplicatedStorage when a server package depends on a shared one", function()
		const build = buildSiblingPackageLink("Promise", PACKAGE_ID, MODULE_NAME, "server", "shared")
		expect(build.source).toBe(
			`return require(game.ReplicatedStorage.Packages._Index["{PACKAGE_ID}"]["{MODULE_NAME}"])`
		)
	end)

	--[[
		Resolve can promote a server package to shared after its own server
			dependencies were placed, as wally does. The link then reaches into the
			server index, the path the wally CLI's `link_server_index` writes.
	]]
	it("reaches into ServerStorage when a shared package depends on a server one", function()
		const build = buildSiblingPackageLink("Promise", PACKAGE_ID, MODULE_NAME, "shared", "server")
		expect(build.source).toBe(
			`return require(game.ServerStorage.ServerPackages._Index["{PACKAGE_ID}"]["{MODULE_NAME}"])`
		)
	end)
end)

describe("buildRootPackageLink", function()
	--[[
		A root is written into the Packages folder of its own realm, so its link
			never crosses realms and takes no realm arguments.
	]]
	it("descends into _Index from the Packages folder", function()
		const build = buildRootPackageLink("Promise", PACKAGE_ID, MODULE_NAME)
		expect(build.source).toBe(`return require(script.Parent._Index["{PACKAGE_ID}"]["{MODULE_NAME}"])`)
	end)
end)
