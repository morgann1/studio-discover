--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const parseLink = require(ServerScriptService.StudioDiscover.Libraries.PackageTypes.parseLink)

describe("parseLink", function()
	it("reads a link the wally CLI writes", function()
		expect(parseLink('return require(script.Parent._Index["evaera_promise@4.0.0"]["promise"])\n')).toEqual({
			indexPath = "script.Parent._Index",
			packageId = "evaera_promise@4.0.0",
			moduleName = "promise",
		})
	end)

	it("reads a link that forwards its target's types", function()
		const source = table.concat({
			'local REQUIRED_MODULE = require(script.Parent.Parent["sleitnick_signal@2.0.3"]["signal"])',
			"export type Signal<T...> = REQUIRED_MODULE.Signal<T...>",
			"return REQUIRED_MODULE",
		}, "\n")

		expect(parseLink(source)).toEqual({
			indexPath = "script.Parent.Parent",
			packageId = "sleitnick_signal@2.0.3",
			moduleName = "signal",
		})
	end)

	it("rejects a package module that indexes a string containing @", function()
		const source = table.concat({
			"local Promise = require(script.Parent.Promise)",
			'local handlers = { ["user@example"] = true }',
			'return handlers["user@example"]["x"]',
		}, "\n")

		expect(parseLink(source)).toBeNil()
	end)
end)
