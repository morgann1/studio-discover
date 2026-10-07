--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const buildTree = require(ServerScriptService.StudioDiscover.Libraries.Core.buildTree)

-- Archives arrive with everything under one top-level directory, which buildTree drops.
const function entry(path: string, content: string?): buildTree.Entry
	return { path = path, content = content or "return nil" }
end

describe("buildTree", function()
	it("drops the archive's top-level directory and keeps the rest", function()
		const root = buildTree({ entry("archive-root/nested/thing.luau") }, "Pkg")
		expect(root.Name).toBe("Pkg")
		const nested = root:FindFirstChild("nested")
		expect(nested).never.toBeNil()
		expect((nested :: Instance):FindFirstChild("thing")).never.toBeNil()
	end)

	it("promotes a folder's init file into a ModuleScript named for the folder", function()
		const root = buildTree({
			entry("archive-root/Sub/init.luau"),
			entry("archive-root/Sub/helper.luau"),
		}, "Pkg")

		const sub = root:FindFirstChild("Sub")
		expect(sub).never.toBeNil()
		expect((sub :: Instance):IsA("ModuleScript")).toBe(true)
		expect((sub :: Instance):FindFirstChild("helper")).never.toBeNil()
	end)

	it("promotes a root init file into the package root itself", function()
		const root = buildTree({
			entry("archive-root/init.luau"),
			entry("archive-root/helper.luau"),
		}, "Pkg")

		expect(root:IsA("ModuleScript")).toBe(true)
		expect(root.Name).toBe("Pkg")
		expect(root:FindFirstChild("helper")).never.toBeNil()
	end)

	it("returns each script with the source it still needs", function()
		const _, pending = buildTree({ entry("archive-root/thing.luau", "return 42") }, "Pkg")
		expect(#pending).toBe(1)

		const item = pending[1]
		assert(item.kind == "script", "expected a script")
		expect(item.content).toBe("return 42")
		expect(item.script:IsA("ModuleScript")).toBe(true)
	end)

	it("holds a model's place with a folder named for it, which moves with an init promotion", function()
		const root, pending = buildTree({
			entry("archive-root/Shared/TagList.rbxmx", "<roblox />"),
			entry("archive-root/Shared/init.luau"),
		}, "Pkg")

		const shared = root:FindFirstChild("Shared")
		const placeholder = if shared ~= nil then shared:FindFirstChild("TagList") else nil
		expect(placeholder).never.toBeNil()

		const models = {}
		for _, item in pending do
			if item.kind == "model" then
				table.insert(models, item)
			end
		end

		expect(#models).toBe(1)
		expect(models[1].placeholder).toBe(placeholder)
		expect(models[1].content).toBe("<roblox />")
	end)

	it("leaves non-Luau files out of the tree", function()
		const root, pending = buildTree({
			entry("archive-root/thing.luau"),
			entry("archive-root/README.md"),
		}, "Pkg")

		expect(#root:GetChildren()).toBe(1)
		expect(#pending).toBe(1)
	end)
end)
