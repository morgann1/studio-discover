--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")
const ServerStorage = game:GetService("ServerStorage")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const afterEach = JestGlobals.afterEach
const beforeEach = JestGlobals.beforeEach
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it
const jest = JestGlobals.jest

const StudioDiscover = ServerScriptService.StudioDiscover
const PesdeRegistry = StudioDiscover.Libraries.PesdeRegistry
const fetchMetadataAsync = require(PesdeRegistry.Api.fetchMetadataAsync)
const types = require(PesdeRegistry.types)

type PesdeResolvedPackage = types.PesdeResolvedPackage

-- Every version of each `spec/<name>` package, with the `spec/d` constraint it depends on, if any.
const REGISTRY: { [string]: { [string]: string | false } } = {
	a = { ["1.0.0"] = "^1.0.0" },
	b = { ["1.0.0"] = false, ["1.1.0"] = false },
	c = { ["1.0.0"] = false },
	d = { ["1.0.0"] = false, ["1.1.0"] = false },
}

jest.mock(PesdeRegistry.Api.fetchMetadataAsync, function()
	return function(_scope: string, name: string): (fetchMetadataAsync.PesdeMetadata?, string?)
		const versions = REGISTRY[name]
		if versions == nil then
			return nil, "not found"
		end

		const entries: { fetchMetadataAsync.VersionEntry } = {}
		for version, dReq in versions do
			table.insert(entries, {
				version = version,
				target = "roblox",
				libPath = "lib/init.luau",
				dependencies = if dReq == false
					then {}
					else {
						{ alias = "D", kind = "pesde", name = "spec/d", versionReq = dReq, ty = "standard" },
					},
				authors = {},
			})
		end

		return { versions = entries }, nil
	end
end)

-- Applying downloads archives, so the spec records the graph it was handed instead.
local applied: { [string]: PesdeResolvedPackage } = {}
jest.mock(PesdeRegistry.applyAsync, function()
	return function(resolved: { [string]: PesdeResolvedPackage }): { string }
		applied = resolved
		return {}
	end
end)

const buildPackageLink = require(PesdeRegistry.buildPackageLink)
const installPesdeAsync = require(StudioDiscover.Source.Installer.installPesdeAsync)
const packagesFolder = require(PesdeRegistry.packagesFolder)
const replaceModuleAsync = require(StudioDiscover.Libraries.Core.replaceModuleAsync)
const saveLockfileAsync = require(PesdeRegistry.saveLockfileAsync)
const uninstallPesdeAsync = require(StudioDiscover.Source.Installer.uninstallPesdeAsync)
const updateAllPesdeAsync = require(StudioDiscover.Source.Installer.updateAllPesdeAsync)

const function lockedPackage(name: string, version: string, dReq: string?): PesdeResolvedPackage
	return {
		packageId = `spec/{name}@{version} roblox`,
		scope = "spec",
		name = name,
		version = version,
		realm = "shared",
		libPath = "lib/init.luau",
		dependencies = if dReq ~= nil then { { alias = "D", packageId = dReq } } else {},
	}
end

--[[
	Installs roots A and B in the shared realm, with A's dependency on D locked at
		1.0.0 even though 1.1.0 satisfies it.
]]
beforeEach(function()
	applied = {}

	const a = lockedPackage("a", "1.0.0", "spec/d@1.0.0 roblox")
	const b = lockedPackage("b", "1.0.0")
	saveLockfileAsync({
		[a.packageId] = a,
		[b.packageId] = b,
		["spec/d@1.0.0 roblox"] = lockedPackage("d", "1.0.0"),
	})

	const folder = packagesFolder.get("shared")
	for alias, pkg in { A = a, B = b } do
		replaceModuleAsync(folder, alias, buildPackageLink.buildTopLevelLink(alias, pkg).source)
	end
end)

afterEach(function()
	const lock = ServerStorage:FindFirstChild("PesdeLock")
	if lock ~= nil then
		lock:Destroy()
	end

	const folder = packagesFolder.find("shared")
	if folder ~= nil then
		folder:Destroy()
	end
end)

describe("pesde lockfile use", function()
	it("keeps installed dependencies where they are when installing another package", function()
		const result = installPesdeAsync({
			registry = "pesde",
			scope = "spec",
			name = "c",
			version = "1.0.0",
			realm = "shared",
		})

		expect(result.ok).toBe(true)
		expect(applied["spec/d@1.0.0 roblox"]).never.toBeNil()
		expect(applied["spec/d@1.1.0 roblox"]).toBeNil()
	end)

	it("keeps installed dependencies where they are when uninstalling another package", function()
		const result = uninstallPesdeAsync({
			scope = "spec",
			name = "b",
			version = "1.0.0",
			realm = "shared",
			alias = "B",
			registry = "pesde",
		})

		expect(result.ok).toBe(true)
		expect(applied["spec/d@1.0.0 roblox"]).never.toBeNil()
		expect(applied["spec/d@1.1.0 roblox"]).toBeNil()
	end)

	it("moves every dependency to its newest match when updating", function()
		const result = updateAllPesdeAsync({
			{
				registry = "pesde",
				scope = "spec",
				name = "b",
				realm = "shared",
				alias = "B",
				installedVersion = "1.0.0",
				latestVersion = "1.1.0",
			},
		})

		expect(result.ok).toBe(true)
		expect(applied["spec/d@1.1.0 roblox"]).never.toBeNil()
		expect(applied["spec/d@1.0.0 roblox"]).toBeNil()
	end)
end)
