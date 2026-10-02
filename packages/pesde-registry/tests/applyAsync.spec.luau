--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const afterEach = JestGlobals.afterEach
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it
const jest = JestGlobals.jest

const Libraries = ServerScriptService.StudioDiscover.Libraries
const buildTree = require(Libraries.Core.buildTree)
const coreTypes = require(Libraries.Core.types)
const realms = require(Libraries.Core.realms)
const formatPackageId = require(Libraries.PesdeRegistry.formatPackageId)
const packagesFolder = require(Libraries.PesdeRegistry.packagesFolder)
const targetFromRealm = require(Libraries.PesdeRegistry.targetFromRealm)
const types = require(Libraries.PesdeRegistry.types)

type Archive = {
	read libPath: string,
	read failSourceWrite: boolean?,
}

-- The source of a module whose write Studio rejects.
const REJECTED_SOURCE = "-- rejected"

-- What the mocked registry serves, keyed by `scope/name@version`, and every download apply asked for.
const archives: { [string]: Archive } = {}
const downloads: { string } = {}

jest.mock(Libraries.PesdeRegistry.downloadAndExtractAsync, function()
	return function(scope: string, name: string, version: string)
		const key = `{scope}/{name}@{version}`
		table.insert(downloads, key)

		const archive = archives[key]
		if archive == nil then
			return { ok = false, error = `no archive for {key}` }
		end

		const source = if archive.failSourceWrite == true then REJECTED_SOURCE else "return {}"
		const tree, pending = buildTree({ { path = `{name}/{archive.libPath}`, content = source } }, name)
		return { ok = true, tree = tree, pending = pending, libPath = archive.libPath }
	end
end)

-- Studio gives no way to make a source write fail on demand, so one source stands in for a rejected write.
jest.mock(Libraries.Core.setScriptSourceAsync, function()
	const actual = jest.requireActual(Libraries.Core.setScriptSourceAsync)
	return function(script: LuaSourceContainer, content: string)
		if content == REJECTED_SOURCE then
			return false, "rejected"
		end

		return actual(script, content)
	end
end)

const applyAsync = require(Libraries.PesdeRegistry.applyAsync)

-- A resolved `spec/signal` at `version`. Fresh each call, since apply fills in `libPath`.
const function signal(version: string, realm: coreTypes.Realm): types.PesdeResolvedPackage
	return {
		packageId = formatPackageId("spec", "signal", version, targetFromRealm(realm)),
		scope = "spec",
		name = "signal",
		version = version,
		realm = realm,
		dependencies = {},
	}
end

const function graph(packages: { types.PesdeResolvedPackage }): { [string]: types.PesdeResolvedPackage }
	const resolved = {}
	for _, pkg in packages do
		resolved[pkg.packageId] = pkg
	end

	return resolved
end

const function findContainer(realm: coreTypes.Realm): Instance?
	const index = packagesFolder.findIndex(realm)
	return if index ~= nil then index:FindFirstChild("spec+signal") else nil
end

-- The installed root of `spec/signal@version`, or nil when that version is not in the place.
const function findRoot(realm: coreTypes.Realm, version: string): Instance?
	const container = findContainer(realm)
	const versionFolder = if container ~= nil then container:FindFirstChild(version) else nil
	return if versionFolder ~= nil then versionFolder:FindFirstChild("signal") else nil
end

-- The path a root alias requires, or nil when apply wrote no such alias.
const function linkTarget(realm: coreTypes.Realm, alias: string): string?
	const folder = packagesFolder.find(realm)
	const link = if folder ~= nil then folder:FindFirstChild(alias) else nil
	if link == nil or not link:IsA("ModuleScript") then
		return nil
	end

	return link.Source:match('require%("([^"]+)"%)')
end

afterEach(function()
	for _, realm in realms do
		const folder = packagesFolder.find(realm)
		if folder ~= nil then
			folder:Destroy()
		end
	end

	table.clear(archives)
	table.clear(downloads)
end)

describe("applyAsync with two versions of one package", function()
	it("keeps each version's own lib path without downloading either again", function()
		archives["spec/signal@1.0.0"] = { libPath = "src/init.luau" }
		archives["spec/signal@2.0.0"] = { libPath = "lib/init.luau" }

		const old, new = signal("1.0.0", "shared"), signal("2.0.0", "shared")
		applyAsync(graph({ old, new }), { [old.packageId] = "Old", [new.packageId] = "New" })

		const keptOld, keptNew = signal("1.0.0", "shared"), signal("2.0.0", "shared")
		const failures =
			applyAsync(graph({ keptOld, keptNew }), { [keptOld.packageId] = "Old", [keptNew.packageId] = "New" })

		expect(failures).toEqual({})
		expect(#downloads).toBe(2)
		expect(linkTarget("shared", "Old")).toBe("./.pesde/spec+signal/1.0.0/signal/src")
		expect(linkTarget("shared", "New")).toBe("./.pesde/spec+signal/2.0.0/signal/lib")
	end)

	it("keeps an installed version when another version's source write fails", function()
		archives["spec/signal@1.0.0"] = { libPath = "src/init.luau" }
		archives["spec/signal@2.0.0"] = { libPath = "src/init.luau", failSourceWrite = true }

		const old = signal("1.0.0", "shared")
		applyAsync(graph({ old }), { [old.packageId] = "Old" })

		const keptOld, new = signal("1.0.0", "shared"), signal("2.0.0", "shared")
		const failures = applyAsync(graph({ keptOld, new }), { [keptOld.packageId] = "Old", [new.packageId] = "New" })

		expect(#failures).toBe(1)
		expect(failures[1]:sub(1, #new.packageId)).toBe(new.packageId)
		expect(findRoot("shared", "1.0.0")).never.toBeNil()
		expect(findRoot("shared", "2.0.0")).toBeNil()
		expect(linkTarget("shared", "Old")).toBe("./.pesde/spec+signal/1.0.0/signal/src")
	end)

	it("leaves the other version in place when one is dropped", function()
		archives["spec/signal@1.0.0"] = { libPath = "src/init.luau" }
		archives["spec/signal@2.0.0"] = { libPath = "src/init.luau" }

		const old, new = signal("1.0.0", "shared"), signal("2.0.0", "shared")
		applyAsync(graph({ old, new }), { [old.packageId] = "Old", [new.packageId] = "New" })

		const keptNew = signal("2.0.0", "shared")
		const failures = applyAsync(graph({ keptNew }), { [keptNew.packageId] = "New" })

		expect(failures).toEqual({})
		expect(#downloads).toBe(2)
		expect(findRoot("shared", "1.0.0")).toBeNil()
		expect(findRoot("shared", "2.0.0")).never.toBeNil()
	end)

	it("removes the container a package leaves empty when its realm changes", function()
		archives["spec/signal@1.0.0"] = { libPath = "src/init.luau" }

		const shared = signal("1.0.0", "shared")
		applyAsync(graph({ shared }), { [shared.packageId] = "Signal" })

		const server = signal("1.0.0", "server")
		const failures = applyAsync(graph({ server }), { [server.packageId] = "Signal" })

		expect(failures).toEqual({})
		expect(findContainer("shared")).toBeNil()
		expect(findRoot("server", "1.0.0")).never.toBeNil()
	end)

	--[[
		Before versions tracked their own id, the container carried one `PackageId`
			and `LibPath`, for the version installed last. That version is adopted
			as installed. Any other version in the container is downloaded again.
	]]
	it("keeps the version a pre-fix container names and downloads the others", function()
		archives["spec/signal@2.0.0"] = { libPath = "lib/init.luau" }

		const container = Instance.new("Folder")
		container.Name = "spec+signal"
		container:SetAttribute("PackageId", signal("1.0.0", "shared").packageId)
		container:SetAttribute("LibPath", "src/init.luau")
		container.Parent = packagesFolder.getIndex("shared")

		const legacyVersions = {
			{ version = "1.0.0", libPath = "src/init.luau" },
			{ version = "2.0.0", libPath = "lib/init.luau" },
		}
		for _, entry in legacyVersions do
			const versionFolder = Instance.new("Folder")
			versionFolder.Name = entry.version
			versionFolder.Parent = container

			const tree = buildTree({ { path = `signal/{entry.libPath}`, content = "return {}" } }, "signal")
			tree.Parent = versionFolder
		end

		const old, new = signal("1.0.0", "shared"), signal("2.0.0", "shared")
		const failures = applyAsync(graph({ old, new }), { [old.packageId] = "Old", [new.packageId] = "New" })

		expect(failures).toEqual({})
		expect(downloads).toEqual({ "spec/signal@2.0.0" })
		expect(linkTarget("shared", "Old")).toBe("./.pesde/spec+signal/1.0.0/signal/src")
		expect(linkTarget("shared", "New")).toBe("./.pesde/spec+signal/2.0.0/signal/lib")
		expect(container:GetAttribute("PackageId")).toBeNil()
		expect(container:GetAttribute("LibPath")).toBeNil()
	end)
end)
