--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const isMissing = require(ServerScriptService.StudioDiscover.Libraries.WallyRegistry.Api.isMissing)

-- What api.wally.run answered for /package-metadata/nobody-here/nothing-here.
const NOT_IN_INDEX =
	[[{"message":"could not open package nobody-here/nothing-here from index\n\nCaused by:\n    0: failed to open file `/tmp/.tmpNs7ASa/nobody-here/nothing-here`\n    1: No such file or directory (os error 2)"}]]

describe("isMissing", function()
	it("treats Wally's 500 for a package outside its index as missing", function()
		expect(isMissing(500, NOT_IN_INDEX)).toBe(true)
	end)

	it("treats a 404 as missing", function()
		expect(isMissing(404, nil)).toBe(true)
	end)

	it("keeps any other server error a failure", function()
		expect(isMissing(500, [[{"message":"database unavailable"}]])).toBe(false)
		expect(isMissing(503, nil)).toBe(false)
	end)
end)
