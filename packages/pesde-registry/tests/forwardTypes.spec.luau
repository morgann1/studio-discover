--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const forwardTypes = require(ServerScriptService.StudioDiscover.Libraries.PesdeRegistry.forwardTypes)

describe("forwardTypes", function()
	it("forwards a plain alias and a generic one through the module variable", function()
		const source = table.concat({
			"export type Foo = { x: number }",
			"export type Bar<T, U...> = (T) -> U...",
		}, "\n")

		expect(forwardTypes(source, "module")).toEqual({
			"export type Foo = module.Foo",
			"export type Bar<T, U...> = module.Bar<T, U...>",
		})
	end)

	--[[
		Unlike wally-package-types, pesde never strips a default, even one naming a
			type the link module cannot see.
	]]
	it("copies every default onto the declaration and passes names in the reference", function()
		const source = "export type Store<S = { T }, D = Outside.Thing, R... = ...any> = S"

		expect(forwardTypes(source, "module")).toEqual({
			"export type Store<S = { T }, D = Outside.Thing, R... = ...any> = module.Store<S, D, R...>",
		})
	end)

	it("forwards a type function under its own parameter names", function()
		expect(forwardTypes("export type function keyof(a, b, ...) end", "module")).toEqual({
			"export type keyof<a, b> = module.keyof<a, b>",
		})
	end)

	it("skips a type function with no named parameters", function()
		const source = "export type function none() end\nexport type function rest(...) end"

		expect(forwardTypes(source, "module")).toEqual({})
	end)
end)
