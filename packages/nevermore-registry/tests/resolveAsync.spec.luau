--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const beforeEach = JestGlobals.beforeEach
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it
const jest = JestGlobals.jest

const NevermoreRegistry = ServerScriptService.StudioDiscover.Libraries.NevermoreRegistry
const types = require(NevermoreRegistry.types)

--[[
	The registry these specs resolve against: each package name maps its versions to
		their dependencies, by npm name to range.
]]
const REGISTRY: { [string]: { [string]: { [string]: string } } } = {
	["@q/blend"] = {
		["1.0.0"] = { ["@q/maid"] = "1.0.0", ["@q/t"] = "^3.0.0" },
	},
	["@q/rx"] = {
		["1.0.0"] = { ["@q/maid"] = "1.0.0" },
	},
	["@q/maid"] = {
		["1.0.0"] = {},
		["1.1.0"] = {},
	},
	["@q/t"] = {
		["3.0.0"] = {},
		["3.2.0"] = {},
		["4.0.0"] = {},
	},
}

-- Every request the specs made, as "version name@version" or "packument name".
const requests: { string } = {}

jest.mock(NevermoreRegistry.Api.fetchVersionAsync, function()
	return function(name: string, version: string)
		table.insert(requests, `version {name}@{version}`)

		const versions = REGISTRY[name]
		const dependencies = if versions ~= nil then versions[version] else nil
		if dependencies == nil then
			return nil, "not found", true
		end

		return { version = version, dependencies = dependencies, authors = {} }, nil, false
	end
end)

jest.mock(NevermoreRegistry.Api.fetchPackumentAsync, function()
	return function(name: string)
		table.insert(requests, `packument {name}`)

		const versions = REGISTRY[name]
		if versions == nil then
			return nil, "not found", true
		end

		const entries = {}
		for version, dependencies in versions do
			table.insert(entries, { version = version, dependencies = dependencies })
		end

		return { versions = entries }, nil, false
	end
end)

const resolveAsync = require(NevermoreRegistry.resolveAsync)

const function root(name: string, version: string)
	return { scope = "q", name = name, version = version, requestRealm = "shared" :: "shared", alias = name }
end

-- Each resolved package id, mapped to the ids it depends on, sorted.
const function edges(resolved: { [string]: types.NevermoreResolvedPackage }): { [string]: { string } }
	const result: { [string]: { string } } = {}
	for id, pkg in resolved do
		const dependencyIds = {}
		for _, dependency in pkg.dependencies do
			table.insert(dependencyIds, dependency.packageId)
		end
		table.sort(dependencyIds)

		result[id] = dependencyIds
	end

	return result
end

beforeEach(function()
	table.clear(requests)
end)

describe("resolveAsync", function()
	it("takes a pinned version as is and the newest match for a range", function()
		const resolved, rootIds, failures, unresolved = resolveAsync({ root("blend", "1.0.0") }, {}, nil)

		expect(failures).toEqual({})
		expect(unresolved).toEqual({})
		expect(rootIds).toEqual({ "@q/blend@1.0.0" })
		expect(edges(resolved)).toEqual({
			["@q/blend@1.0.0"] = { "@q/maid@1.0.0", "@q/t@3.2.0" },
			["@q/maid@1.0.0"] = {},
			["@q/t@3.2.0"] = {},
		})
	end)

	it("fetches a pinned version on its own instead of every version", function()
		resolveAsync({ root("rx", "1.0.0") }, {}, nil)

		expect(requests).toEqual({ "version @q/rx@1.0.0", "version @q/maid@1.0.0" })
	end)

	it("shares one copy of a package two roots pin to the same version", function()
		const resolved = resolveAsync({ root("blend", "1.0.0"), root("rx", "1.0.0") }, {}, nil)

		expect(edges(resolved)["@q/rx@1.0.0"]).toEqual({ "@q/maid@1.0.0" })

		local maidRequests = 0
		for _, request in requests do
			if request == "version @q/maid@1.0.0" then
				maidRequests += 1
			end
		end
		expect(maidRequests).toBe(1)
	end)

	it("keeps a root's locked subtree without fetching anything", function()
		const locked: { [string]: types.NevermoreResolvedPackage } = {
			["@q/rx@1.0.0"] = {
				packageId = "@q/rx@1.0.0",
				name = "@q/rx",
				version = "1.0.0",
				dependencies = { { alias = "@q/maid", packageId = "@q/maid@1.1.0" } },
			},
			["@q/maid@1.1.0"] = { packageId = "@q/maid@1.1.0", name = "@q/maid", version = "1.1.0", dependencies = {} },
		}

		const resolved = resolveAsync({ root("rx", "1.0.0") }, locked, nil)

		expect(requests).toEqual({})
		expect(edges(resolved)).toEqual({
			["@q/rx@1.0.0"] = { "@q/maid@1.1.0" },
			["@q/maid@1.1.0"] = {},
		})
	end)

	it("reports a root it can't find instead of dropping it", function()
		const _, rootIds, failures, unresolved = resolveAsync({ root("missing", "1.0.0") }, {}, nil)

		expect(rootIds).toEqual({})
		expect(#failures).toBe(1)
		expect(unresolved).toEqual({ root("missing", "1.0.0") })
	end)
end)
