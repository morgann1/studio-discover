--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const npm = require(ServerScriptService.StudioDiscover.Libraries.Semver.npm)

type Row = {
	read range: string,
	read matches: { string },
	read misses: { string },
}

--[[
	One row per range form a package.json can hold, each checked against versions on
		both sides of its bounds. The bounds are node-semver's.
]]
const rows: { Row } = {
	{ range = "1.2.3", matches = { "1.2.3" }, misses = { "1.2.2", "1.2.4", "1.9.0" } },
	{ range = "v1.2.3", matches = { "1.2.3" }, misses = { "1.2.4" } },
	{ range = "3.10.0-quenty.2", matches = { "3.10.0-quenty.2" }, misses = { "3.10.0-quenty.1", "3.10.0" } },
	{ range = "1.2", matches = { "1.2.0", "1.2.9" }, misses = { "1.1.9", "1.3.0" } },
	{ range = "1.x", matches = { "1.0.0", "1.9.9" }, misses = { "0.9.9", "2.0.0" } },
	{ range = "^1.2.3", matches = { "1.2.3", "1.9.0" }, misses = { "1.2.2", "2.0.0", "1.5.0-rc.1" } },
	{ range = "^0.2.3", matches = { "0.2.3", "0.2.9" }, misses = { "0.2.2", "0.3.0" } },
	{ range = "^0.0.3", matches = { "0.0.3" }, misses = { "0.0.4" } },
	{
		range = "^1.12.0-quenty.0",
		matches = { "1.12.0-quenty.0", "1.12.0-quenty.1", "1.12.0", "1.13.0" },
		misses = { "1.13.0-quenty.0", "2.0.0" },
	},
	{ range = "~1.2.3", matches = { "1.2.3", "1.2.9" }, misses = { "1.2.2", "1.3.0" } },
	{ range = ">=1.0.0 <2.0.0", matches = { "1.0.0", "1.9.9" }, misses = { "0.9.9", "2.0.0" } },
	{ range = ">= 1.0.0 < 2.0.0", matches = { "1.0.0", "1.9.9" }, misses = { "0.9.9", "2.0.0" } },
	{ range = "1.2.0 - 1.4", matches = { "1.2.0", "1.4.9" }, misses = { "1.1.9", "1.5.0" } },
	{ range = "^1.0.0 || ^3.0.0", matches = { "1.5.0", "3.1.0" }, misses = { "2.0.0", "4.0.0" } },
	{ range = "*", matches = { "0.1.0", "9.9.9" }, misses = { "2.0.0-rc.1" } },
	{ range = "", matches = { "0.1.0", "9.9.9" }, misses = { "2.0.0-rc.1" } },
}

-- The versions in `versions` that satisfy `range`, in order.
const function matching(range: string, versions: { string }): { string }
	const satisfies = npm.buildSatisfies(range)
	assert(satisfies ~= nil, "expected the range to parse")

	const matched = {}
	for _, version in versions do
		if satisfies(version) then
			table.insert(matched, version)
		end
	end

	return matched
end

describe("npm.buildSatisfies", function()
	for _, row in rows do
		it(`reads "{row.range}" with node-semver bounds`, function()
			const versions = table.clone(row.matches)
			table.move(row.misses, 1, #row.misses, #versions + 1, versions)

			expect(matching(row.range, versions)).toEqual(row.matches)
		end)
	end

	it("fails a range that does not parse instead of matching everything", function()
		for _, range in { "banana", "workspace:*", "github:quenty/maid", "latest" } do
			expect({ range = range, parsed = npm.buildSatisfies(range) ~= nil }).toEqual({
				range = range,
				parsed = false,
			})
		end
	end)
end)
