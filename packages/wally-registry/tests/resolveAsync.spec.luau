--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it
const jest = JestGlobals.jest

const StudioDiscover = ServerScriptService.StudioDiscover
const WallyRegistry = StudioDiscover.Libraries.WallyRegistry

const coreTypes = require(StudioDiscover.Libraries.Core.types)

const ANY_1 = ">=1.0.0, <2.0.0"

-- One published version, 1.0.0, with the realm and dependencies its manifest declares.
const function manifest(
	realm: coreTypes.Realm,
	dependencies: coreTypes.DependencyMap,
	serverDependencies: coreTypes.DependencyMap
): coreTypes.PackageMetadata
	return {
		versions = {
			{
				package = { authors = {}, realm = realm, version = "1.0.0" },
				dependencies = dependencies,
				["server-dependencies"] = serverDependencies,
				["dev-dependencies"] = {},
			},
		},
	}
end

--[[
	The registry as resolve sees it. `a` declares `realm = "server"` and pulls in
		`b`, also server. `shared-app` reaches `a` one level down, through the shared
		package `c`.
]]
const REGISTRY: { [string]: coreTypes.PackageMetadata? } = {
	["scope/server-root"] = manifest("server", {}, { A = `scope/a@{ANY_1}` }),
	["scope/shared-root"] = manifest("shared", { A = `scope/a@{ANY_1}` }, {}),
	["scope/shared-app"] = manifest("shared", { C = `scope/c@{ANY_1}` }, {}),
	["scope/c"] = manifest("shared", { A = `scope/a@{ANY_1}` }, {}),
	["scope/a"] = manifest("server", {}, { B = `scope/b@{ANY_1}` }),
	["scope/b"] = manifest("server", {}, {}),
}

jest.mock(WallyRegistry.Api.getMetadataAsync, function()
	return function(scope: string, name: string): (coreTypes.PackageMetadata?, string?)
		const metadata = REGISTRY[`{scope}/{name}`]
		return metadata, if metadata == nil then "not found" else nil
	end
end)

const resolveAsync = require(WallyRegistry.resolveAsync)

const function root(name: string, realm: coreTypes.Realm): coreTypes.RootRequest
	return { scope = "scope", name = name, version = "1.0.0", requestRealm = realm, alias = name }
end

const SERVER_ROOT = root("server-root", "server")
const SHARED_ROOT = root("shared-root", "shared")
const SHARED_APP = root("shared-app", "shared")

describe("resolveAsync", function()
	--[[
		The server root's request for `a` is visited before `c`'s, which sits a level
			deeper, so `a` and `b` land in server and `c` then reuses `a`. Wally
			promotes only the reused package, so `a` moves to shared, `b` stays in
			server, and apply links across realms to it.
	]]
	it("promotes a reused package without promoting its dependencies", function()
		for _, roots in { { SHARED_APP, SERVER_ROOT }, { SERVER_ROOT, SHARED_APP } } do
			const resolved, _, failures, unresolvedRoots = resolveAsync(roots, {})

			expect(failures).toEqual({})
			expect(unresolvedRoots).toEqual({})
			expect(resolved["scope_a@1.0.0"].realm).toBe("shared")
			expect(resolved["scope_a@1.0.0"].dependencies).toEqual({ { alias = "B", packageId = "scope_b@1.0.0" } })
			expect(resolved["scope_b@1.0.0"].realm).toBe("server")
		end
	end)

	--[[
		Wally visits a project's shared dependencies before its server ones, so it
			rejects `a` for the shared root however the roots are listed. If the
			listed order won, an install could link `a` and a later update, which
			lists shared roots first, would drop that link.
	]]
	it("rejects a server package for a shared root whichever root is listed first", function()
		for _, roots in { { SHARED_ROOT, SERVER_ROOT }, { SERVER_ROOT, SHARED_ROOT } } do
			const resolved, _, failures, unresolvedRoots = resolveAsync(roots, {})

			expect(#failures).toBe(1)
			expect(failures[1]).toContain("scope/a")
			expect(unresolvedRoots).toEqual({})
			expect(resolved["scope_shared-root@1.0.0"].dependencies).toEqual({})
			expect(resolved["scope_a@1.0.0"].realm).toBe("server")
		end
	end)
end)
