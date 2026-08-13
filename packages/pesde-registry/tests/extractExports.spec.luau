--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local test = JestGlobals.test

local StudioDiscover = ServerScriptService:WaitForChild("StudioDiscover") :: Folder
local extractExports = require(StudioDiscover.PesdeRegistry.extractExports)

--[[
	Produces the `export type` lines a pesde link module re-exports, so that types
	survive the indirection the way values already do.
]]

describe("extractExports", function()
	test("forwards a plain type alias", function()
		expect(extractExports("export type Foo = { x: number }")).toEqual({
			"export type Foo = module.Foo",
		})
	end)

	test("forwards generics on both sides", function()
		expect(extractExports("export type Bar<T> = { value: T }")).toEqual({
			"export type Bar<T> = module.Bar<T>",
		})
	end)

	-- The default belongs on the declaration but not on the forwarded reference,
	-- which would be a syntax error.
	test("keeps a generic default on the left and drops it on the right", function()
		expect(extractExports("export type Baz<T = string> = { value: T }")).toEqual({
			"export type Baz<T = string> = module.Baz<T>",
		})
	end)

	test("handles several parameters where only some have defaults", function()
		expect(extractExports("export type Q<T, U = number> = { a: T, b: U }")).toEqual({
			"export type Q<T, U = number> = module.Q<T, U>",
		})
	end)

	test("collects every export in a source file", function()
		local source = [[
			export type A = string
			local x = 1
			export type B<T> = { T }
		]]
		expect(extractExports(source)).toEqual({
			"export type A = module.A",
			"export type B<T> = module.B<T>",
		})
	end)

	test("skips an exported type function, which cannot be forwarded this way", function()
		expect(extractExports("export type function Foo(t) return t end")).toEqual({})
	end)

	test("does not match export type when it is a suffix of a longer word", function()
		expect(extractExports("myexport type Foo = string")).toEqual({})
	end)

	test("ignores a declaration with no assignment", function()
		expect(extractExports("export type Foo")).toEqual({})
	end)

	test("returns an empty list for source with no exports", function()
		expect(extractExports("local x = 1\nreturn x")).toEqual({})
	end)
end)
