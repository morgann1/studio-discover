--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const packageId = require(ServerScriptService.StudioDiscover.WallyRegistry.packageId)

describe("packageId.format", function()
	it("joins scope and name with an underscore and the version with an at sign", function()
		expect(packageId.format("evaera", "promise", "4.0.0")).toBe("evaera_promise@4.0.0")
	end)
end)

describe("packageId.parse", function()
	it("round trips a formatted id", function()
		const scope, name, version = packageId.parse(packageId.format("evaera", "promise", "4.0.0"))
		expect(scope).toBe("evaera")
		expect(name).toBe("promise")
		expect(version).toBe("4.0.0")
	end)

	it("keeps a prerelease attached to the version", function()
		const _, _, version = packageId.parse("evaera_promise@4.0.0-rc.1")
		expect(version).toBe("4.0.0-rc.1")
	end)

	it("returns nils for an id with no version", function()
		const scope, name, version = packageId.parse("evaera_promise")
		expect(scope).toBe(nil)
		expect(name).toBe(nil)
		expect(version).toBe(nil)
	end)

	it("returns nils for an id with no scope", function()
		const scope = packageId.parse("promise@4.0.0")
		expect(scope).toBe(nil)
	end)

	--[[
		wally's own format is ambiguous once a name contains `_`, and its answer is
			to make that unrepresentable: `validate_scope` and `validate_name` in
			`src/package_name.rs` allow only lowercase letters, digits and `-`. So this
			is unreachable for anything the registry can serve, and we match wally's
			greedy split rather than inventing a rule it does not have.
	]]
	it("splits on the last underscore when there is more than one", function()
		const scope, name = packageId.parse("my_scope_lib@1.0.0")
		expect(scope).toBe("my_scope")
		expect(name).toBe("lib")
	end)
end)
