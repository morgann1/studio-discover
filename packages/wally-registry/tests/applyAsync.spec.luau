--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const afterAll = JestGlobals.afterAll
const afterEach = JestGlobals.afterEach
const beforeAll = JestGlobals.beforeAll
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it
const jest = JestGlobals.jest

const StudioDiscover = ServerScriptService.StudioDiscover
const WallyRegistry = StudioDiscover.Libraries.WallyRegistry

const buildTree = require(StudioDiscover.Libraries.Core.buildTree)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const packagesFolder = require(WallyRegistry.packagesFolder)
const realms = require(StudioDiscover.Libraries.Core.realms)
const types = require(WallyRegistry.types)

const VENDORED_NAME = "ApplyAsyncSpecVendoredPackages"

-- Stands in for the registry download: each package is one module that returns its own name.
jest.mock(WallyRegistry.downloadAndExtractAsync, function()
	return function(_scope: string, name: string, _version: string)
		const tree = Instance.new("ModuleScript")
		tree.Name = name

		const pending: { buildTree.PendingSource } =
			{ { kind = "script", script = tree, path = name, content = `return "{name}"` } }
		return { ok = true, tree = tree, pending = pending }
	end
end)

const applyAsync = require(WallyRegistry.applyAsync)

--[[
	`applyAsync` owns each realm's packages folder and removes whatever it did not
		resolve. The test place keeps the plugin's own dependencies in
		`ReplicatedStorage.Packages`, so they step aside while these specs run.
]]
beforeAll(function()
	const vendored = ReplicatedStorage:FindFirstChild("Packages")
	if vendored ~= nil then
		vendored.Name = VENDORED_NAME
	end
end)

afterEach(function()
	for _, realm in realms do
		const folder = packagesFolder.find(realm)
		if folder ~= nil then
			folder:Destroy()
		end
	end
end)

afterAll(function()
	const vendored = ReplicatedStorage:FindFirstChild(VENDORED_NAME)
	if vendored ~= nil then
		vendored.Name = "Packages"
	end
end)

const function resolvedPackage(
	name: string,
	realm: coreTypes.Realm,
	dependencies: { coreTypes.Dependency }
): types.ResolvedPackage
	return {
		scope = "scope",
		name = name,
		version = "1.0.0",
		realm = realm,
		packageId = `scope_{name}@1.0.0`,
		dependencies = dependencies,
	}
end

describe("applyAsync", function()
	--[[
		Resolve can promote a server package to shared after its own server
			dependencies were placed, as wally does. Apply links across realms to
			them instead of failing the install.
	]]
	it("links a shared package to its server dependency", function()
		const failures = applyAsync({
			["scope_a@1.0.0"] = resolvedPackage("a", "shared", { { alias = "B", packageId = "scope_b@1.0.0" } }),
			["scope_b@1.0.0"] = resolvedPackage("b", "server", {}),
		}, { ["scope_a@1.0.0"] = "A" })

		expect(failures).toEqual({})

		const sharedIndex = packagesFolder.findIndex("shared")
		const packageA = if sharedIndex ~= nil then sharedIndex:FindFirstChild("scope_a@1.0.0") else nil
		const link = if packageA ~= nil then packageA:FindFirstChild("B") else nil
		if link == nil or not link:IsA("ModuleScript") then
			error("expected a link module named B in the shared package")
		end

		-- Requiring the link from the shared package reaches `b` in the server index.
		expect(require(link)).toBe("b")
	end)
end)
