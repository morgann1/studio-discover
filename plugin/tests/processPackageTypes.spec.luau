--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local test = JestGlobals.test

local StudioDiscover = ServerScriptService:WaitForChild("StudioDiscover") :: Folder
local processPackageTypes = require(StudioDiscover.Source.Installer.Wally.processPackageTypes)

local extractExportedTypes = processPackageTypes.extractExportedTypes
local extractDefaultType = processPackageTypes.extractDefaultType
local splitGenerics = processPackageTypes.splitGenerics
local shouldKeepDefault = processPackageTypes.shouldKeepDefault

describe("splitGenerics", function()
	test("returns empty list when there are no generics", function()
		expect(splitGenerics("")).toEqual({})
	end)

	test("splits a single param", function()
		expect(splitGenerics("<T>")).toEqual({ "T" })
	end)

	test("splits multiple params at top-level commas", function()
		expect(splitGenerics("<T, U>")).toEqual({ "T", " U" })
	end)

	test("ignores commas nested in angle brackets", function()
		expect(splitGenerics("<T, U<V, W>>")).toEqual({ "T", " U<V, W>" })
	end)

	test("ignores commas nested in parens (function types)", function()
		expect(splitGenerics("<T = (a, b) -> c, U>")).toEqual({ "T = (a, b) -> c", " U" })
	end)

	test("ignores commas nested in braces (table types)", function()
		expect(splitGenerics("<T = {x: number, y: number}, U>")).toEqual({ "T = {x: number, y: number}", " U" })
	end)
end)

describe("extractDefaultType", function()
	test("returns nil when there is no default", function()
		expect(extractDefaultType("T")).toBeNil()
	end)

	test("captures a bare identifier default", function()
		expect(extractDefaultType("T = number")).toBe("number")
	end)

	test("captures a namespaced default", function()
		expect(extractDefaultType("T = Foo.Bar")).toBe("Foo.Bar")
	end)

	test("captures a function-type default", function()
		expect(extractDefaultType("T = (...any) -> ()")).toBe("(...any) -> ()")
	end)

	test("captures a table-type default", function()
		expect(extractDefaultType("T = {[string]: number}")).toBe("{[string]: number}")
	end)

	test("captures a generic-type default", function()
		expect(extractDefaultType("T = Array<string>")).toBe("Array<string>")
	end)

	test("ignores '=' nested inside angle brackets", function()
		expect(extractDefaultType("T = Pair<A = B, C>")).toBe("Pair<A = B, C>")
	end)
end)

describe("shouldKeepDefault", function()
	test("keeps a builtin default", function()
		expect(shouldKeepDefault("number", {})).toBe(true)
	end)

	test("keeps a default that references a resolved type", function()
		expect(shouldKeepDefault("Self", { Self = true })).toBe(true)
	end)

	test("drops a default with namespace access", function()
		expect(shouldKeepDefault("Foo.Bar", {})).toBe(false)
	end)

	test("keeps a function-type default made of builtins", function()
		expect(shouldKeepDefault("(...any) -> ()", {})).toBe(true)
	end)

	test("drops a function-type default that references an unresolved type", function()
		expect(shouldKeepDefault("(Unknown) -> ()", {})).toBe(false)
	end)
end)

describe("extractExportedTypes", function()
	test("finds a simple alias export", function()
		local types = extractExportedTypes("export type Foo = number")
		expect(#types).toBe(1)
		expect(types[1].name).toBe("Foo")
		expect(types[1].generics).toBe("")
		expect(types[1].kind).toBe("alias")
	end)

	test("finds a single-line generic export", function()
		local types = extractExportedTypes("export type Foo<T> = T")
		expect(#types).toBe(1)
		expect(types[1].generics).toBe("<T>")
	end)

	test("ignores non-export types", function()
		local types = extractExportedTypes("type Foo = number")
		expect(#types).toBe(0)
	end)

	test("finds multiple exports across lines", function()
		local src = "export type Foo = number\nexport type Bar = string"
		local types = extractExportedTypes(src)
		expect(#types).toBe(2)
		expect(types[1].name).toBe("Foo")
		expect(types[2].name).toBe("Bar")
	end)

	test("finds a type whose generic header spans multiple lines", function()
		local src = table.concat({
			"export type Foo<",
			"    T,",
			"    U = number",
			"> = T",
		}, "\n")
		local types = extractExportedTypes(src)
		expect(#types).toBe(1)
		expect(types[1].name).toBe("Foo")
		expect(types[1].generics:find("T") ~= nil).toBe(true)
		expect(types[1].generics:find("U") ~= nil).toBe(true)
	end)

	test("recognises export type function with kind = function", function()
		local src = "export type function Concat(a, b) return a end"
		local types = extractExportedTypes(src)
		expect(#types).toBe(1)
		expect(types[1].name).toBe("Concat")
		expect(types[1].kind).toBe("function")
	end)

	test("does not match export type in the middle of a line", function()
		local types = extractExportedTypes("local notAnExport = 'export type Fake = number'")
		expect(#types).toBe(0)
	end)

	test("captures generic header when a default contains a function arrow", function()
		local types = extractExportedTypes("export type Handler<T = (...any) -> ()> = T")
		expect(#types).toBe(1)
		expect(types[1].name).toBe("Handler")
		expect(types[1].generics).toBe("<T = (...any) -> ()>")
	end)
end)
