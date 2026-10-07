--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")
const StarterPlayer = game:GetService("StarterPlayer")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const afterEach = JestGlobals.afterEach
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it
const jest = JestGlobals.jest

const Libraries = ServerScriptService.StudioDiscover.Libraries
const NevermoreRegistry = Libraries.NevermoreRegistry
const buildTree = require(Libraries.Core.buildTree)
const gameFolder = require(NevermoreRegistry.gameFolder)
const packageAttributes = require(NevermoreRegistry.packageAttributes)
const types = require(NevermoreRegistry.types)

-- Every download apply asked for, as "name@version", and the ones the mocked registry fails.
const downloads: { string } = {}
const failingDownloads: { [string]: true? } = {}

-- Each package is one module that returns its own id.
jest.mock(NevermoreRegistry.downloadAndExtractAsync, function()
	return function(name: string, version: string)
		const id = `{name}@{version}`
		table.insert(downloads, id)

		if failingDownloads[id] then
			return { ok = false, error = "no such tarball" }
		end

		const folderName = name:match("([^/]+)$") or name
		const tree, pending = buildTree({ { path = `{folderName}/init.luau`, content = `return "{id}"` } }, folderName)
		return { ok = true, tree = tree, pending = pending }
	end
end)

const applyAsync = require(NevermoreRegistry.applyAsync)
const snapshotRoots = require(NevermoreRegistry.snapshotRoots)

-- Builds a graph from "name@version" ids to the ids each depends on.
const function graph(edges: { [string]: { string } }): { [string]: types.NevermoreResolvedPackage }
	const resolved: { [string]: types.NevermoreResolvedPackage } = {}
	for id, dependencyIds in edges do
		const name, version = id:match("^(.+)@([^@]+)$")
		assert(name ~= nil and version ~= nil, "expected name@version")

		const dependencies = {}
		for _, dependencyId in dependencyIds do
			table.insert(
				dependencies,
				{ alias = dependencyId:match("^(.+)@") or dependencyId, packageId = dependencyId }
			)
		end

		resolved[id] = { packageId = id, name = name, version = version, dependencies = dependencies }
	end

	return resolved
end

-- The instance at a path of names under `node_modules`, such as { "@q", "rx", "node_modules", "@q", "maid" }.
const function find(path: { string }): Instance?
	local current: Instance? = gameFolder.findNodeModules()
	for _, name in path do
		if current == nil then
			return nil
		end

		current = current:FindFirstChild(name)
	end

	return current
end

const function playerScripts(): Instance
	return assert(StarterPlayer:FindFirstChildOfClass("StarterPlayerScripts"), "expected StarterPlayerScripts")
end

afterEach(function()
	for _, instance in
		{
			ServerScriptService:FindFirstChild(gameFolder.NAME),
			ServerScriptService:FindFirstChild(`{gameFolder.NAME}Scripts`),
			playerScripts():FindFirstChild(`{gameFolder.NAME}Scripts`),
		}
	do
		instance:Destroy()
	end

	table.clear(downloads)
	table.clear(failingDownloads)
end)

describe("applyAsync", function()
	it("sets a game up for the loader on the first install, as nevermore init does", function()
		const failures = applyAsync(graph({ ["@q/rx@1.0.0"] = {} }), { "@q/rx@1.0.0" }, nil)

		expect(failures).toEqual({})

		const root = ServerScriptService:FindFirstChild(gameFolder.NAME)
		assert(root ~= nil, "expected the game folder")
		for _, name in { "Client", "Server", "Shared" } do
			expect((root:FindFirstChild("game") :: Instance):FindFirstChild(name)).never.toBeNil()
		end

		const serverMain = (ServerScriptService:FindFirstChild(`{gameFolder.NAME}Scripts`) :: Instance):FindFirstChild(
			"ServerMain"
		)
		assert(serverMain ~= nil and serverMain:IsA("Script"), "expected ServerMain")
		expect((string.find(serverMain.Source, "bootstrapGame", 1, true))).never.toBeNil()

		const clientMain = (playerScripts():FindFirstChild(`{gameFolder.NAME}Scripts`) :: Instance):FindFirstChild(
			"ClientMain"
		)
		expect(clientMain ~= nil and clientMain:IsA("LocalScript")).toBe(true)
	end)

	it("installs scoped packages in their scope folder, marking the roots", function()
		applyAsync(graph({ ["@q/rx@1.0.0"] = { "@q/maid@1.0.0" }, ["@q/maid@1.0.0"] = {} }), { "@q/rx@1.0.0" }, nil)

		const rx = find({ "@q", "rx" })
		const maid = find({ "@q", "maid" })
		assert(rx ~= nil and maid ~= nil, "expected both packages")
		expect(rx:IsA("ModuleScript")).toBe(true)
		expect(rx:GetAttribute(packageAttributes.PACKAGE_ID)).toBe("@q/rx@1.0.0")
		expect(rx:GetAttribute(packageAttributes.ROOT)).toBe(true)
		expect(maid:GetAttribute(packageAttributes.ROOT)).toBeNil()

		expect(snapshotRoots()).toEqual({
			{ scope = "q", name = "rx", version = "1.0.0", requestRealm = "shared", alias = "rx" },
		})
	end)

	it("nests a conflicting version in the package that needs it", function()
		applyAsync(
			graph({
				["@q/maid@2.0.0"] = {},
				["@q/rx@1.0.0"] = { "@q/maid@1.0.0" },
				["@q/maid@1.0.0"] = {},
			}),
			{ "@q/maid@2.0.0", "@q/rx@1.0.0" },
			nil
		)

		const nested = find({ "@q", "rx", "node_modules", "@q", "maid" })
		assert(nested ~= nil, "expected the nested copy")
		expect(nested:GetAttribute(packageAttributes.PACKAGE_ID)).toBe("@q/maid@1.0.0")
		expect((find({ "@q", "maid" }) :: Instance):GetAttribute(packageAttributes.PACKAGE_ID)).toBe("@q/maid@2.0.0")
	end)

	it("keeps what is already in place instead of downloading it again", function()
		const resolved = graph({ ["@q/rx@1.0.0"] = { "@q/maid@1.0.0" }, ["@q/maid@1.0.0"] = {} })
		applyAsync(resolved, { "@q/rx@1.0.0" }, nil)
		const rx = find({ "@q", "rx" })
		table.clear(downloads)

		applyAsync(resolved, { "@q/rx@1.0.0" }, nil)

		expect(downloads).toEqual({})
		expect(find({ "@q", "rx" })).toBe(rx)
	end)

	it("copies a package that moves instead of downloading it again", function()
		applyAsync(
			graph({
				["@q/maid@2.0.0"] = {},
				["@q/rx@1.0.0"] = { "@q/maid@1.0.0" },
				["@q/maid@1.0.0"] = {},
			}),
			{ "@q/maid@2.0.0", "@q/rx@1.0.0" },
			nil
		)
		table.clear(downloads)

		-- Without the 2.0.0 root, rx's maid moves up to the top.
		applyAsync(graph({ ["@q/rx@1.0.0"] = { "@q/maid@1.0.0" }, ["@q/maid@1.0.0"] = {} }), { "@q/rx@1.0.0" }, nil)

		expect(downloads).toEqual({})
		expect((find({ "@q", "maid" }) :: Instance):GetAttribute(packageAttributes.PACKAGE_ID)).toBe("@q/maid@1.0.0")
		expect(find({ "@q", "rx", "node_modules" })).toBeNil()
	end)

	it("removes its own packages on the last uninstall and leaves the rest of the game alone", function()
		applyAsync(graph({ ["@q/rx@1.0.0"] = {} }), { "@q/rx@1.0.0" }, nil)

		const untracked = Instance.new("Folder")
		untracked.Name = "mine"
		untracked.Parent = gameFolder.findNodeModules()

		applyAsync({}, {}, nil)

		expect(find({ "@q" })).toBeNil()
		expect(find({ "mine" })).toBe(untracked)
		expect(ServerScriptService:FindFirstChild(gameFolder.NAME)).never.toBeNil()
		expect(snapshotRoots()).toEqual({})
	end)

	it("reports a package that fails to download, prefixed with its id", function()
		failingDownloads["@q/rx@1.0.0"] = true

		const failures = applyAsync(graph({ ["@q/rx@1.0.0"] = {} }), { "@q/rx@1.0.0" }, nil)

		expect(failures).toEqual({ "@q/rx@1.0.0: no such tarball" })
		expect(find({ "@q", "rx" })).toBeNil()
	end)
end)
