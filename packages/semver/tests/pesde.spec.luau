--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const pesde = require(ServerScriptService.StudioDiscover.Libraries.Semver.pesde)

type Row = {
	read constraint: string,
	read matches: { string },
	read misses: { string },
}

--[[
	One row per constraint form pesde can send, each checked against versions on
		both sides of its bounds, prereleases included. The bounds are semver 1.x's,
		which pesde uses.
]]
const rows: { Row } = {
	{ constraint = "1.2.3", matches = { "1.2.3", "1.9.0" }, misses = { "1.2.2", "2.0.0" } },
	{ constraint = "^1.2.3", matches = { "1.2.3", "1.9.0" }, misses = { "1.2.2", "2.0.0" } },
	{ constraint = "^1.2", matches = { "1.2.0", "1.9.9" }, misses = { "1.1.9", "2.0.0" } },
	{ constraint = "^1", matches = { "1.0.0", "1.9.9" }, misses = { "0.9.9", "2.0.0" } },
	{ constraint = "^0.2.3", matches = { "0.2.3", "0.2.9" }, misses = { "0.2.2", "0.3.0" } },
	{ constraint = "^0.0.3", matches = { "0.0.3" }, misses = { "0.0.2", "0.0.4" } },
	{ constraint = "^0.0", matches = { "0.0.0", "0.0.9" }, misses = { "0.1.0" } },
	{ constraint = "^0", matches = { "0.0.0", "0.9.9" }, misses = { "1.0.0" } },
	{ constraint = "~1.2.3", matches = { "1.2.3", "1.2.9" }, misses = { "1.2.2", "1.3.0" } },
	{ constraint = "~1.2", matches = { "1.2.0", "1.2.9" }, misses = { "1.1.9", "1.3.0" } },
	{ constraint = "~1", matches = { "1.0.0", "1.9.9" }, misses = { "0.9.9", "2.0.0" } },
	{ constraint = "~0.2.3", matches = { "0.2.3", "0.2.9" }, misses = { "0.2.2", "0.3.0" } },
	{ constraint = "~0.0.3", matches = { "0.0.3", "0.0.9" }, misses = { "0.0.2", "0.1.0" } },
	{
		constraint = "~1.2.3-rc.1",
		matches = { "1.2.3-rc.1", "1.2.3-rc.2", "1.2.3", "1.2.9" },
		misses = { "1.2.3-alpha", "1.2.4-rc.1", "1.3.0" },
	},
	{ constraint = "^1.0.0", matches = { "1.5.0" }, misses = { "1.5.0-rc.1", "2.0.0-rc.1" } },
	{ constraint = ">=2.0.0-rc.1", matches = { "2.0.0-rc.2" }, misses = { "2.0.1-rc.1" } },
	{ constraint = "^0.6.0-rc.1", matches = { "0.6.0-rc.6", "0.6.0" }, misses = { "0.6.1-rc.1" } },
	{ constraint = "1.*", matches = { "1.0.0", "1.9.9" }, misses = { "0.9.9", "2.0.0" } },
	{ constraint = "1.x", matches = { "1.0.0", "1.9.9" }, misses = { "0.9.9", "2.0.0" } },
	{ constraint = "1.2.*", matches = { "1.2.0", "1.2.9" }, misses = { "1.1.9", "1.3.0" } },
	{ constraint = "=1.2", matches = { "1.2.0", "1.2.9" }, misses = { "1.1.9", "1.3.0" } },
	{ constraint = "=1.2.3", matches = { "1.2.3" }, misses = { "1.2.2", "1.2.4" } },
	{ constraint = ">1.2", matches = { "1.3.0", "2.0.0" }, misses = { "1.2.0", "1.2.9" } },
	{ constraint = "<=1.2", matches = { "0.1.0", "1.2.9" }, misses = { "1.3.0" } },
	{ constraint = "<2", matches = { "1.9.9" }, misses = { "2.0.0" } },
	{ constraint = ">=1.0, <2", matches = { "1.0.0", "1.9.9" }, misses = { "0.9.9", "2.0.0" } },
	{ constraint = "*", matches = { "0.1.0", "9.9.9", "2.0.0-rc.1" }, misses = {} },
}

-- The versions in `versions` that satisfy `constraint`, in order.
const function matching(constraint: string, versions: { string }): { string }
	const satisfies = pesde.buildSatisfies(constraint)
	assert(satisfies ~= nil, "expected the constraint to parse")

	const matched = {}
	for _, version in versions do
		if satisfies(version) then
			table.insert(matched, version)
		end
	end

	return matched
end

describe("pesde.buildSatisfies", function()
	for _, row in rows do
		it(`reads "{row.constraint}" with semver 1.x bounds`, function()
			const versions = table.clone(row.matches)
			table.move(row.misses, 1, #row.misses, #versions + 1, versions)

			expect(matching(row.constraint, versions)).toEqual(row.matches)
		end)
	end

	it("fails a constraint that does not parse instead of matching everything", function()
		for _, constraint in { "", "banana", "1.2.3 <2.0.0", ">=1.0,", "*, <2", "=>1.0.0" } do
			expect({ constraint = constraint, parsed = pesde.buildSatisfies(constraint) ~= nil }).toEqual({
				constraint = constraint,
				parsed = false,
			})
		end
	end)
end)
