--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it
const jest = JestGlobals.jest

const PesdeRegistry = ServerScriptService.StudioDiscover.Libraries.PesdeRegistry
const fetchMetadataAsync = require(PesdeRegistry.Api.fetchMetadataAsync)
const types = require(PesdeRegistry.types)

type PesdeResolvedPackage = types.PesdeResolvedPackage

--[[
	The registry these specs resolve against, keyed by package name. Each version
		maps a dependency alias to the `spec/<name>` it requires and the constraint.
]]
const REGISTRY: { [string]: { [string]: { [string]: { string } } } } = {
	a = {
		["1.0.0"] = { D = { "d", "^1.0.0" } },
	},
	b = {
		["1.0.0"] = { D = { "d", "^1.0.0" } },
	},
	d = {
		["1.0.0"] = {},
		["1.1.0"] = {},
	},
}

-- Publishes every version for both targets, the way pesde serves a package that supports both realms.
const function buildMetadata(name: string): fetchMetadataAsync.PesdeMetadata?
	const versions = REGISTRY[name]
	if versions == nil then
		return nil
	end

	const entries: { fetchMetadataAsync.VersionEntry } = {}
	for version, dependencies in versions do
		for _, target: types.Target in { "roblox", "roblox_server" } do
			const specs: { fetchMetadataAsync.DependencySpec } = {}
			for alias, dependency in dependencies do
				table.insert(specs, {
					alias = alias,
					kind = "pesde",
					name = `spec/{dependency[1]}`,
					versionReq = dependency[2],
					target = target,
					ty = "standard",
				})
			end

			table.insert(entries, {
				version = version,
				target = target,
				libPath = "lib/init.luau",
				dependencies = specs,
				authors = {},
			})
		end
	end

	return { versions = entries }
end

jest.mock(PesdeRegistry.Api.fetchMetadataAsync, function()
	return function(_scope: string, name: string)
		const metadata = buildMetadata(name)
		if metadata == nil then
			return nil, "not found"
		end

		return metadata, nil
	end
end)

const resolveAsync = require(PesdeRegistry.resolveAsync)

-- One package to lock: its name under the `spec` scope, its version, and its edges by alias.
type LockSpec = {
	read name: string,
	read version: string,
	read dependencies: { [string]: string }?,
}

-- A shared-realm lock, shaped the way `loadLockfile` returns one.
const function buildLock(specs: { LockSpec }): { [string]: PesdeResolvedPackage }
	const lock: { [string]: PesdeResolvedPackage } = {}
	for _, spec in specs do
		const packageId = `spec/{spec.name}@{spec.version} roblox`
		const edges = {}
		for alias, dependencyId in spec.dependencies or {} do
			table.insert(edges, { alias = alias, packageId = dependencyId })
		end

		lock[packageId] = {
			packageId = packageId,
			scope = "spec",
			name = spec.name,
			version = spec.version,
			realm = "shared",
			libPath = "lib/init.luau",
			dependencies = edges,
		}
	end

	return lock
end

const function root(name: string, realm: "shared" | "server")
	return {
		scope = "spec",
		name = name,
		version = "1.0.0",
		requestRealm = realm,
		alias = string.upper(name),
	}
end

-- The id of the package `alias` points at from `packageId`, or nil when there is no such edge.
const function edgeTarget(resolved: { [string]: PesdeResolvedPackage }, packageId: string, alias: string): string?
	const pkg = resolved[packageId]
	for _, dependency in if pkg ~= nil then pkg.dependencies else {} do
		if dependency.alias == alias then
			return dependency.packageId
		end
	end

	return nil
end

describe("resolveAsync", function()
	it("keeps a locked root's subtree when newer versions exist", function()
		const lock = buildLock({
			{ name = "a", version = "1.0.0", dependencies = { D = "spec/d@1.0.0 roblox" } },
			{ name = "d", version = "1.0.0" },
		})

		const resolved, rootAliases, failures = resolveAsync({ root("a", "shared") }, lock, nil)

		expect(failures).toEqual({})
		expect(rootAliases["spec/a@1.0.0 roblox"]).toBe("A")
		expect(edgeTarget(resolved, "spec/a@1.0.0 roblox", "D")).toBe("spec/d@1.0.0 roblox")
		expect(resolved["spec/d@1.1.0 roblox"]).toBeNil()
	end)

	it("resolves a locked root fresh when its locked subtree is incomplete", function()
		const lock = buildLock({
			{ name = "a", version = "1.0.0", dependencies = { D = "spec/d@1.0.0 roblox" } },
		})

		const resolved = resolveAsync({ root("a", "shared") }, lock, nil)

		expect(edgeTarget(resolved, "spec/a@1.0.0 roblox", "D")).toBe("spec/d@1.1.0 roblox")
		expect(resolved["spec/d@1.0.0 roblox"]).toBeNil()
	end)

	it("resolves a new root fresh but reuses a locked version that satisfies it", function()
		const lock = buildLock({
			{ name = "a", version = "1.0.0", dependencies = { D = "spec/d@1.0.0 roblox" } },
			{ name = "d", version = "1.0.0" },
		})

		const resolved = resolveAsync({ root("a", "shared"), root("b", "shared") }, lock, nil)

		expect(edgeTarget(resolved, "spec/b@1.0.0 roblox", "D")).toBe("spec/d@1.0.0 roblox")
		expect(resolved["spec/d@1.1.0 roblox"]).toBeNil()
	end)

	it("resolves every root to the newest match without a lock", function()
		const resolved = resolveAsync({ root("a", "shared") }, {}, nil)

		expect(edgeTarget(resolved, "spec/a@1.0.0 roblox", "D")).toBe("spec/d@1.1.0 roblox")
	end)

	it("does not lock a server root to the same package's shared entry", function()
		const lock = buildLock({
			{ name = "a", version = "1.0.0", dependencies = { D = "spec/d@1.0.0 roblox" } },
			{ name = "d", version = "1.0.0" },
		})

		const resolved = resolveAsync({ root("a", "server") }, lock, nil)

		expect(edgeTarget(resolved, "spec/a@1.0.0 roblox_server", "D")).toBe("spec/d@1.1.0 roblox_server")
		expect(resolved["spec/a@1.0.0 roblox"]).toBeNil()
	end)
end)
