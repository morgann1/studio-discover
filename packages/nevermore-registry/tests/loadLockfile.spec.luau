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
const loadLockfile = require(StudioDiscover.Libraries.NevermoreRegistry.loadLockfile)
const replaceModuleAsync = require(StudioDiscover.Libraries.Core.replaceModuleAsync)
const saveLockfileAsync = require(StudioDiscover.Libraries.NevermoreRegistry.saveLockfileAsync)

const LOCKFILE_NAME = "NevermoreLock"

afterEach(function()
	const lock = ServerStorage:FindFirstChild(LOCKFILE_NAME)
	if lock ~= nil then
		lock:Destroy()
	end
end)

describe("loadLockfile", function()
	it("reads back what saveLockfileAsync wrote", function()
		const resolved = {
			["@quenty/rx@1.0.0"] = {
				packageId = "@quenty/rx@1.0.0",
				name = "@quenty/rx",
				version = "1.0.0",
				dependencies = { { alias = "@quenty/maid", packageId = "@quenty/maid@3.12.1" } },
			},
			["@quenty/maid@3.12.1"] = {
				packageId = "@quenty/maid@3.12.1",
				name = "@quenty/maid",
				version = "3.12.1",
				dependencies = {},
			},
		}

		saveLockfileAsync(resolved)

		expect(loadLockfile()).toEqual(resolved)
	end)

	it("skips an entry whose id does not match its name and version", function()
		replaceModuleAsync(
			ServerStorage,
			LOCKFILE_NAME,
			[[return {
	{ packageId = "@quenty/maid@3.12.1", name = "@quenty/maid", version = "3.12.0", dependencies = {} },
	{ packageId = "@quenty/rx@1.0.0", name = "@quenty/rx", version = "1.0.0", dependencies = {} },
}]]
		)

		const lock = loadLockfile()

		expect(lock["@quenty/maid@3.12.1"]).toBeNil()
		expect(lock["@quenty/rx@1.0.0"]).never.toBeNil()
	end)
end)
