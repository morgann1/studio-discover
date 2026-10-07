--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const classifyFile = require(ServerScriptService.StudioDiscover.Libraries.Core.classifyFile)

describe("classifyFile", function()
	it("maps a file suffix to the class of script it becomes", function()
		expect(classifyFile("pkg/init.server.luau")).toBe("Script")
		expect(classifyFile("pkg/main.client.lua")).toBe("LocalScript")
		expect(classifyFile("pkg/util.luau")).toBe("ModuleScript")
	end)

	it("maps a model file to a model", function()
		expect(classifyFile("pkg/TagList.rbxmx")).toBe("Model")
		expect(classifyFile("pkg/Assets.rbxm")).toBe("Model")
	end)

	it("skips anything that is neither Luau source nor a model", function()
		expect(classifyFile("pkg/README.md")).toBe("skip")
		expect(classifyFile("pkg/default.project.json")).toBe("skip")
	end)
end)
