--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const parseToml = require(ServerScriptService.StudioDiscover.Core.parseToml)

describe("parseToml", function()
	it("reads keys into the table their header names", function()
		const manifest = parseToml(table.concat({
			'name = "pesde/hello"',
			"",
			"[target]",
			'environment = "roblox"',
			'lib = "src/init.luau"',
		}, "\n"))

		expect(manifest).toEqual({
			name = "pesde/hello",
			target = {
				environment = "roblox",
				lib = "src/init.luau",
			},
		})
	end)

	it("reads dotted, quoted, and array-of-table headers", function()
		const manifest = parseToml(table.concat({
			'[dependencies."foo.bar"]',
			"version = 2",
			"[[scripts.hooks]]",
			"enabled = true",
			"[[scripts.hooks]]",
			'paths = ["a", "b"]',
		}, "\n"))

		expect(manifest).toEqual({
			dependencies = { ["foo.bar"] = { version = 2 } },
			scripts = {
				hooks = {
					{ enabled = true },
					{ paths = { "a", "b" } },
				},
			},
		})
	end)

	it("ignores spaces inside a header and backslashes in literal array items", function()
		const manifest = parseToml(table.concat({
			"[ target ]",
			[=[paths = ['C:\', 'x']]=],
		}, "\n"))

		expect(manifest).toEqual({ target = { paths = { "C:\\", "x" } } })
	end)

	it("reads a header with trailing whitespace and CRLF line endings", function()
		const manifest = parseToml('[target]  \r\nlib = "init.luau"\r\n')

		expect(manifest).toEqual({ target = { lib = "init.luau" } })
	end)

	it("drops trailing comments and reads each kind of string", function()
		const manifest = parseToml(table.concat({
			'lib = "src/init.luau" # the entry point',
			[[escaped = "a\\nb # kept"]],
			[[literal = 'C:\path\n']],
		}, "\n"))

		expect(manifest).toEqual({
			lib = "src/init.luau",
			escaped = "a\\nb # kept",
			literal = "C:\\path\\n",
		})
	end)
end)
