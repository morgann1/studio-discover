--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const forwardTypes = require(ServerScriptService.StudioDiscover.Libraries.PackageTypes.forwardTypes)

describe("forwardTypes", function()
	it("forwards a plain alias and a generic one through the module variable", function()
		const source = table.concat({
			"export type Foo = { x: number }",
			"local x = 1",
			"export type Bar<T> = { value: T }",
		}, "\n")

		expect(forwardTypes(source, "module")).toEqual({
			"export type Foo = module.Foo",
			"export type Bar<T> = module.Bar<T>",
		})
	end)

	--[[
		The default belongs on the declaration but not on the forwarded reference,
			which would be a syntax error.
	]]
	it("keeps an in-scope default on the declaration and drops it from the reference", function()
		expect(forwardTypes("export type Q<T, U = number> = { a: T, b: U }", "module")).toEqual({
			"export type Q<T, U = number> = module.Q<T, U>",
		})
	end)

	it("drops a default that names a type the link module cannot see", function()
		expect(forwardTypes("export type R<T = Outside.Thing> = T", "REQUIRED_MODULE")).toEqual({
			"export type R<T> = REQUIRED_MODULE.R<T>",
		})
	end)

	it("forwards a type function with one generic per parameter", function()
		expect(forwardTypes("export type function Pick(a, b) return a end", "module")).toEqual({
			"export type Pick<T0, T1> = module.Pick<T0, T1>",
		})
	end)

	it("ignores exports inside comments and strings", function()
		const source = "-- export type Fake = number\nlocal s = 'export type Also = string'\nexport type Real = string"

		expect(forwardTypes(source, "module")).toEqual({ "export type Real = module.Real" })
	end)
end)
