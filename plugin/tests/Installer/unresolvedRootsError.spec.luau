--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const test = JestGlobals.test

const unresolvedRootsError = require(ServerScriptService.StudioDiscover.Source.Installer.unresolvedRootsError)

describe("unresolvedRootsError", function()
	test("lets the operation continue when every root resolved", function()
		expect(unresolvedRootsError({}, { "dep: could not parse" })).toBeNil()
	end)

	test("names every root that did not resolve, with the failures", function()
		const message = unresolvedRootsError({
			{ scope = "evaera", name = "promise", version = "4.0.0", requestRealm = "shared", alias = "Promise" },
			{ scope = "sleitnick", name = "signal", version = "2.0.3", requestRealm = "server", alias = "Signal" },
		}, { "evaera/promise: HTTP 503" })

		expect(message).toBe(
			"Failed to resolve evaera/promise@4.0.0, sleitnick/signal@2.0.3 (evaera/promise: HTTP 503)"
		)
	end)
end)
