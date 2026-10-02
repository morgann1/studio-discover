--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")
const ServerStorage = game:GetService("ServerStorage")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const afterEach = JestGlobals.afterEach
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const StudioDiscover = ServerScriptService.StudioDiscover
const loadLockfile = require(StudioDiscover.Libraries.PesdeRegistry.loadLockfile)
const replaceModuleAsync = require(StudioDiscover.Libraries.Core.replaceModuleAsync)
const saveLockfileAsync = require(StudioDiscover.Libraries.PesdeRegistry.saveLockfileAsync)

const LOCKFILE_NAME = "PesdeLock"

afterEach(function()
	const lock = ServerStorage:FindFirstChild(LOCKFILE_NAME)
	if lock ~= nil then
		lock:Destroy()
	end
end)

describe("loadLockfile", function()
	it("reads back what saveLockfileAsync wrote, in both realms", function()
		const resolved = {
			["spec/a@1.0.0 roblox"] = {
				packageId = "spec/a@1.0.0 roblox",
				scope = "spec",
				name = "a",
				version = "1.0.0",
				realm = "shared" :: "shared",
				libPath = "lib/init.luau",
				dependencies = { { alias = "D", packageId = "spec/d@1.0.0 roblox" } },
			},
			["spec/d@1.0.0 roblox"] = {
				packageId = "spec/d@1.0.0 roblox",
				scope = "spec",
				name = "d",
				version = "1.0.0",
				realm = "shared" :: "shared",
				dependencies = {},
			},
			["spec/a@1.0.0 roblox_server"] = {
				packageId = "spec/a@1.0.0 roblox_server",
				scope = "spec",
				name = "a",
				version = "1.0.0",
				realm = "server" :: "server",
				dependencies = {},
			},
		}

		saveLockfileAsync(resolved)

		expect(loadLockfile()).toEqual(resolved)
	end)

	it("reads a missing lockfile as empty", function()
		expect(loadLockfile()).toEqual({})
	end)

	it("reads a lockfile that fails to load as empty", function()
		replaceModuleAsync(ServerStorage, LOCKFILE_NAME, "return {")

		expect(loadLockfile()).toEqual({})
	end)

	it("skips malformed entries and keeps the rest", function()
		replaceModuleAsync(
			ServerStorage,
			LOCKFILE_NAME,
			[[return {
	{ packageId = "spec/a@1.0.0 roblox", name = "spec/a", version = "1.0.0", realm = "shared", dependencies = {} },
	{ packageId = "spec/b@1.0.0 roblox", name = "spec/b", realm = "shared", dependencies = {} },
	{ packageId = "spec/c@1.0.0 roblox", name = "spec/c", version = "1.0.0", realm = "dev", dependencies = {} },
	{ packageId = "spec/e@1.0.0 roblox", name = "spec/e", version = "1.0.0", realm = "shared", dependencies = { 7 } },
	"spec/f@1.0.0 roblox",
}]]
		)

		const lock = loadLockfile()

		expect(lock["spec/a@1.0.0 roblox"]).never.toBeNil()
		expect(lock["spec/b@1.0.0 roblox"]).toBeNil()
		expect(lock["spec/c@1.0.0 roblox"]).toBeNil()
		expect(lock["spec/e@1.0.0 roblox"]).toBeNil()
	end)

	it("skips an entry whose id does not match its name, version, and realm", function()
		replaceModuleAsync(
			ServerStorage,
			LOCKFILE_NAME,
			[[return {
	{ packageId = "spec/a@1.0.0 roblox_server", name = "spec/a", version = "1.0.0", realm = "shared", dependencies = {} },
}]]
		)

		expect(loadLockfile()).toEqual({})
	end)
end)
