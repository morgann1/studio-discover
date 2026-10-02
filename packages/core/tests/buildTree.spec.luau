--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const buildTree = require(ServerScriptService.StudioDiscover.Core.buildTree)

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
		expect(pending[1].content).toBe("return 42")
		expect(pending[1].script:IsA("ModuleScript")).toBe(true)
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
