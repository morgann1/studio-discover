--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const SerializationService = game:GetService("SerializationService")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const Core = ServerScriptService.StudioDiscover.Libraries.Core
const buildTree = require(Core.buildTree)
const writePendingSourcesAsync = require(Core.writePendingSourcesAsync)

-- A tag list the way Nevermore's packages ship one, as an XML model.
const TAG_LIST_XML = [[<roblox version="4">
	<Item class="Folder" referent="RBX0">
		<Properties>
			<string name="Name">TagList</string>
		</Properties>
		<Item class="Configuration" referent="RBX1">
			<Properties>
				<string name="Name">Hide</string>
			</Properties>
		</Item>
	</Item>
</roblox>]]

-- The binary model of `instances`, as Studio saves a `.rbxm`.
const function binaryModel(instances: { Instance }): string
	return buffer.tostring(SerializationService:SerializeInstancesAsync(instances))
end

describe("writePendingSourcesAsync", function()
	it("writes each script's source", function()
		const root, pending = buildTree({ { path = "archive/thing.luau", content = "return 42" } }, "Pkg")

		expect(writePendingSourcesAsync(pending)).toBeNil()

		const thing = root:FindFirstChild("thing")
		assert(thing ~= nil and thing:IsA("ModuleScript"), "expected the module")
		expect(thing.Source).toBe("return 42")
	end)

	it("swaps an XML model's placeholder for the instance it holds, named for the file", function()
		const root, pending = buildTree({ { path = "archive/HideTagList.rbxmx", content = TAG_LIST_XML } }, "Pkg")

		expect(writePendingSourcesAsync(pending)).toBeNil()

		const tagList = root:FindFirstChild("HideTagList")
		assert(tagList ~= nil, "expected the model")
		expect(tagList.ClassName).toBe("Folder")
		expect(tagList:FindFirstChild("Hide")).never.toBeNil()
		expect(#root:GetChildren()).toBe(1)
	end)

	it("reads a binary model too", function()
		const part = Instance.new("Part")
		const content = binaryModel({ part })
		part:Destroy()

		const root, pending = buildTree({ { path = "archive/Block.rbxm", content = content } }, "Pkg")

		expect(writePendingSourcesAsync(pending)).toBeNil()

		const block = root:FindFirstChild("Block")
		expect(block ~= nil and block:IsA("Part")).toBe(true)
	end)

	it("fails on a model holding more than one instance, naming the file", function()
		const first, second = Instance.new("Folder"), Instance.new("Folder")
		const content = binaryModel({ first, second })
		first:Destroy()
		second:Destroy()

		const _, pending = buildTree({ { path = "archive/Two.rbxm", content = content } }, "Pkg")

		const failure = writePendingSourcesAsync(pending)
		expect(failure).never.toBeNil()
		expect((string.find(failure or "", "archive/Two.rbxm", 1, true))).toBe(1)
	end)
end)
