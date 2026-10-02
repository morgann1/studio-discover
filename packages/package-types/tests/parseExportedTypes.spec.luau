--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const parseExportedTypes = require(ServerScriptService.StudioDiscover.Libraries.PackageTypes.parseExportedTypes)

const extractExportedTypes = parseExportedTypes.extractExportedTypes
const extractDefaultType = parseExportedTypes.extractDefaultType
const splitGenerics = parseExportedTypes.splitGenerics
const shouldKeepDefault = parseExportedTypes.shouldKeepDefault
const stripUnknownDefaults = parseExportedTypes.stripUnknownDefaults

describe("splitGenerics", function()
	it("returns empty list when there are no generics", function()
		expect(splitGenerics("")).toEqual({})
	end)

	it("splits a single param", function()
		expect(splitGenerics("<T>")).toEqual({ "T" })
	end)

	it("splits multiple params at top-level commas", function()
		expect(splitGenerics("<T, U>")).toEqual({ "T", " U" })
	end)

	it("ignores commas nested in angle brackets", function()
		expect(splitGenerics("<T, U<V, W>>")).toEqual({ "T", " U<V, W>" })
	end)

	it("ignores commas nested in parens (function types)", function()
		expect(splitGenerics("<T = (a, b) -> c, U>")).toEqual({ "T = (a, b) -> c", " U" })
	end)

	it("ignores commas nested in braces (table types)", function()
		expect(splitGenerics("<T = {x: number, y: number}, U>")).toEqual({ "T = {x: number, y: number}", " U" })
	end)

	it("keeps union defaults intact", function()
		expect(splitGenerics("<T = A | B, U>")).toEqual({ "T = A | B", " U" })
	end)

	it("keeps intersection defaults intact", function()
		expect(splitGenerics("<T = A & B, U>")).toEqual({ "T = A & B", " U" })
	end)

	it("handles optional-type defaults", function()
		expect(splitGenerics("<T = number?, U>")).toEqual({ "T = number?", " U" })
	end)

	it("handles variadic type-pack params", function()
		expect(splitGenerics("<T..., U>")).toEqual({ "T...", " U" })
	end)

	it("handles generic function-type defaults", function()
		expect(splitGenerics("<F = <T>(T) -> T, U>")).toEqual({ "F = <T>(T) -> T", " U" })
	end)

	it("handles indexer-table defaults", function()
		expect(splitGenerics("<T = { [string]: number }, U>")).toEqual({
			"T = { [string]: number }",
			" U",
		})
	end)
end)

describe("extractDefaultType", function()
	it("returns nil when there is no default", function()
		expect(extractDefaultType("T")).toBeNil()
	end)

	it("captures a bare identifier default", function()
		expect(extractDefaultType("T = number")).toBe("number")
	end)

	it("captures a namespaced default", function()
		expect(extractDefaultType("T = Foo.Bar")).toBe("Foo.Bar")
	end)

	it("captures a function-type default", function()
		expect(extractDefaultType("T = (...any) -> ()")).toBe("(...any) -> ()")
	end)

	it("captures a table-type default", function()
		expect(extractDefaultType("T = {[string]: number}")).toBe("{[string]: number}")
	end)

	it("captures a generic-type default", function()
		expect(extractDefaultType("T = Array<string>")).toBe("Array<string>")
	end)

	it("ignores '=' nested inside angle brackets", function()
		expect(extractDefaultType("T = Pair<A = B, C>")).toBe("Pair<A = B, C>")
	end)

	it("captures singleton literal defaults", function()
		expect(extractDefaultType('T = "open"')).toBe('"open"')
		expect(extractDefaultType("T = true")).toBe("true")
		expect(extractDefaultType("T = 42")).toBe("42")
	end)

	it("captures typeof defaults", function()
		expect(extractDefaultType("T = typeof(workspace)")).toBe("typeof(workspace)")
	end)
end)

describe("shouldKeepDefault", function()
	it("keeps a builtin default", function()
		expect(shouldKeepDefault("number", {})).toBe(true)
	end)

	it("keeps a default that references a resolved type", function()
		expect(shouldKeepDefault("Self", { Self = true })).toBe(true)
	end)

	it("drops a default with namespace access", function()
		expect(shouldKeepDefault("Foo.Bar", {})).toBe(false)
	end)

	it("keeps a function-type default made of builtins", function()
		expect(shouldKeepDefault("(...any) -> ()", {})).toBe(true)
	end)

	it("drops a function-type default that references an unresolved type", function()
		expect(shouldKeepDefault("(Unknown) -> ()", {})).toBe(false)
	end)

	it("keeps a union of builtins", function()
		expect(shouldKeepDefault("number | string", {})).toBe(true)
	end)

	it("keeps a typeof expression made of keywords", function()
		expect(shouldKeepDefault("typeof(nil)", {})).toBe(true)
	end)

	it("drops a union that references an external namespaced type", function()
		expect(shouldKeepDefault("number | Foo.Bar", {})).toBe(false)
	end)
end)

describe("extractExportedTypes", function()
	it("finds a simple alias export", function()
		const types = extractExportedTypes("export type Foo = number")
		expect(#types).toBe(1)
		expect(types[1].name).toBe("Foo")
		expect(types[1].generics).toBe("")
		expect(types[1].kind).toBe("alias")
	end)

	it("finds a single-line generic export", function()
		const types = extractExportedTypes("export type Foo<T> = T")
		expect(#types).toBe(1)
		expect(types[1].generics).toBe("<T>")
	end)

	it("ignores non-export types", function()
		const types = extractExportedTypes("type Foo = number")
		expect(#types).toBe(0)
	end)

	it("finds multiple exports across lines", function()
		const src = "export type Foo = number\nexport type Bar = string"
		const types = extractExportedTypes(src)
		expect(#types).toBe(2)
		expect(types[1].name).toBe("Foo")
		expect(types[2].name).toBe("Bar")
	end)

	it("finds a type whose generic header spans multiple lines", function()
		const src = table.concat({
			"export type Foo<",
			"    T,",
			"    U = number",
			"> = T",
		}, "\n")
		const types = extractExportedTypes(src)
		expect(#types).toBe(1)
		expect(types[1].name).toBe("Foo")
		expect(types[1].generics:find("T") ~= nil).toBe(true)
		expect(types[1].generics:find("U") ~= nil).toBe(true)
	end)

	it("recognises export type function with kind = function", function()
		const src = "export type function Concat(a, b) return a end"
		const types = extractExportedTypes(src)
		expect(#types).toBe(1)
		expect(types[1].name).toBe("Concat")
		expect(types[1].kind).toBe("function")
	end)

	it("captures generic header when a default contains a function arrow", function()
		const types = extractExportedTypes("export type Handler<T = (...any) -> ()> = T")
		expect(#types).toBe(1)
		expect(types[1].name).toBe("Handler")
		expect(types[1].generics).toBe("<T = (...any) -> ()>")
	end)

	it("forwards each type function parameter as a generic", function()
		const types = extractExportedTypes("export type function keyof(a, b) end")
		expect(#types).toBe(1)
		expect(types[1].name).toBe("keyof")
		expect(types[1].kind).toBe("function")
		expect(types[1].generics).toBe("<T0, T1>")
	end)

	it("drops a variadic type function parameter", function()
		const types = extractExportedTypes("export type function keyof(a, b, ...) end")
		expect(types[1].generics).toBe("<T0, T1>")
	end)

	it("gives a variadic-only type function empty generics", function()
		const types = extractExportedTypes("export type function keyof(...) end")
		expect(types[1].generics).toBe("<>")
	end)

	it("skips export type inside a short comment", function()
		const types = extractExportedTypes("-- export type Fake = number\nexport type Real = string")
		expect(#types).toBe(1)
		expect(types[1].name).toBe("Real")
	end)

	it("skips export type inside a long comment", function()
		const src = "--[[\nexport type Fake = number\n]] export type Real = string"
		const types = extractExportedTypes(src)
		expect(#types).toBe(1)
		expect(types[1].name).toBe("Real")
	end)

	it("skips export type inside a leveled long comment", function()
		const src = "--[==[\nexport type Fake = number\n]==]\nexport type Real = string"
		const types = extractExportedTypes(src)
		expect(#types).toBe(1)
		expect(types[1].name).toBe("Real")
	end)

	it("skips export type inside a short string literal", function()
		const types = extractExportedTypes("local s = 'export type Fake = number'\nexport type Real = string")
		expect(#types).toBe(1)
		expect(types[1].name).toBe("Real")
	end)

	it("skips export type inside a long string literal", function()
		const src = "local s = [[\nexport type Fake = number\n]]\nexport type Real = string"
		const types = extractExportedTypes(src)
		expect(#types).toBe(1)
		expect(types[1].name).toBe("Real")
	end)

	it("skips export type inside a leveled long string literal", function()
		const src = "local s = [=[\nexport type Fake = number\n]=]\nexport type Real = string"
		const types = extractExportedTypes(src)
		expect(#types).toBe(1)
		expect(types[1].name).toBe("Real")
	end)

	it("does not match someexport type prefix", function()
		const types = extractExportedTypes("someexport type Fake = number")
		expect(#types).toBe(0)
	end)

	it("captures singleton string default containing >", function()
		const types = extractExportedTypes([[export type Marker<T = ">"> = T]])
		expect(#types).toBe(1)
		expect(types[1].name).toBe("Marker")
		expect(types[1].generics).toBe([[<T = ">">]])
	end)

	it("handles multi-line header with variadic type-pack", function()
		const src = table.concat({
			"export type Handler<",
			"    T...,",
			"    R = ()",
			"> = (T...) -> R",
		}, "\n")
		const types = extractExportedTypes(src)
		expect(#types).toBe(1)
		expect(types[1].name).toBe("Handler")
		expect(types[1].generics:find("T%.%.%.") ~= nil).toBe(true)
		expect(types[1].generics:find("R = %(%)") ~= nil).toBe(true)
	end)
end)

describe("stripUnknownDefaults", function()
	it("keeps a default that only references generics", function()
		expect(stripUnknownDefaults("<T, S = T>", { T = true, S = true })).toBe("<T, S = T>")
	end)

	it("strips earlier defaults when a later default is unknown", function()
		const resolvedTypes = { State = true, Dispatchers = true } :: { [string]: true }
		expect(stripUnknownDefaults("<State = any, Dispatchers = ExternalType>", resolvedTypes)).toBe(
			"<State, Dispatchers>"
		)
	end)
end)
