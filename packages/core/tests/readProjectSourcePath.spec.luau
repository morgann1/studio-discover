--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const Core = ServerScriptService.StudioDiscover.Libraries.Core
const readProjectSourcePath = require(Core.readProjectSourcePath)

describe("readProjectSourcePath", function()
	it("reads the root path, without a leading ./", function()
		expect(readProjectSourcePath('{ "name": "maid", "tree": { "$path": "src" } }')).toBe("src")
		expect(readProjectSourcePath('{ "tree": { "$path": "./DevPackages" } }')).toBe("DevPackages")
	end)

	it("installs the whole archive when the root path is the package itself or missing", function()
		expect(readProjectSourcePath('{ "tree": { "$path": "." } }')).toBeNil()
		expect(readProjectSourcePath('{ "tree": { "$className": "Folder" } }')).toBeNil()
		expect(readProjectSourcePath("not json")).toBeNil()
	end)
end)
