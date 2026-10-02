--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const parseTar = require(ServerScriptService.StudioDiscover.Libraries.PesdeRegistry.parseTar)

const BLOCK_SIZE = 512

const function pad(text: string, length: number): string
	return `{text}{string.rep("\0", length - #text)}`
end

-- One ustar entry: a 512-byte header, then the content padded to whole blocks.
const function entry(name: string, typeFlag: string, content: string): string
	const header = table.concat({
		pad(name, 100),
		pad("0000644", 8),
		pad("0000000", 8),
		pad("0000000", 8),
		pad(string.format("%011o", #content), 12),
		pad("00000000000", 12),
		"000000\0 ",
		typeFlag,
		pad("", 100),
		"ustar\0",
		"00",
		pad("", 32),
		pad("", 32),
		pad("", 8),
		pad("", 8),
		pad("", 155),
		pad("", 12),
	})

	const padding = (BLOCK_SIZE - #content % BLOCK_SIZE) % BLOCK_SIZE
	return `{header}{content}{string.rep("\0", padding)}`
end

const function archive(entries: { string }): string
	return `{table.concat(entries)}{string.rep("\0", BLOCK_SIZE * 2)}`
end

describe("parseTar", function()
	it("reads each file's path and content", function()
		const entries = parseTar(archive({
			entry("init.luau", "0", "return 1"),
			entry("src/util.luau", "0", string.rep("x", 600)),
		}))

		expect(entries).toEqual({
			{ path = "init.luau", content = "return 1" },
			{ path = "src/util.luau", content = string.rep("x", 600) },
		})
	end)

	it("skips directories, marked by type flag or by a trailing slash", function()
		const entries = parseTar(archive({
			entry("src", "5", ""),
			entry("lib/", "0", ""),
			entry("src/init.luau", "0", "return 1"),
		}))

		expect(entries).toEqual({
			{ path = "src/init.luau", content = "return 1" },
		})
	end)

	it("skips hard and symbolic links", function()
		const entries = parseTar(archive({
			entry("init.luau", "0", "return 1"),
			entry("copy.luau", "1", ""),
			entry("alias.luau", "2", ""),
		}))

		expect(entries).toEqual({
			{ path = "init.luau", content = "return 1" },
		})
	end)

	it("reads a long path from the GNU entry before it", function()
		const longPath = `src/{string.rep("nested/", 15)}module.luau`
		const entries = parseTar(archive({
			entry("././@LongLink", "L", `{longPath}\0`),
			entry(string.sub(longPath, 1, 100), "0", "return 1"),
		}))

		expect(entries).toEqual({
			{ path = longPath, content = "return 1" },
		})
	end)

	it("reads a long path from the pax header before it", function()
		const longPath = `src/{string.rep("nested/", 15)}module.luau`
		const record = `path={longPath}\n`
		const entries = parseTar(archive({
			entry("PaxHeader/module.luau", "x", `{#record + 4} {record}`),
			entry("module.luau", "0", "return 1"),
		}))

		expect(entries).toEqual({
			{ path = longPath, content = "return 1" },
		})
	end)
end)
