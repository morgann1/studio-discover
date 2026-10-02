--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const createPackagesFolders = require(ServerScriptService.StudioDiscover.Libraries.Core.createPackagesFolders)

describe("createPackagesFolders", function()
	it("names where each realm's folder lives, as the user finds it in the Explorer", function()
		const folders = createPackagesFolders({ shared = "Packages", server = "ServerPackages", index = "_Index" })

		expect(folders.path("shared")).toBe("ReplicatedStorage.Packages")
		expect(folders.path("server")).toBe("ServerStorage.ServerPackages")
	end)
end)
