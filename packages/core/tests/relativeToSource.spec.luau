--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const Core = ServerScriptService.StudioDiscover.Libraries.Core
const relativeToSource = require(Core.relativeToSource)

describe("relativeToSource", function()
	it("keeps only what sits under the source path, relative to it", function()
		expect(relativeToSource("src/Shared/Maid.lua", "src")).toBe("Shared/Maid.lua")
		expect(relativeToSource("README.md", "src")).toBeNil()
		expect(relativeToSource("srcs/Thing.lua", "src")).toBeNil()
	end)

	it("makes a single-file source path the package's init file", function()
		expect(relativeToSource("lib.luau", "lib")).toBe("init.luau")
	end)

	it("keeps everything when there is no source path", function()
		expect(relativeToSource("lib/init.luau", nil)).toBe("lib/init.luau")
	end)
end)
