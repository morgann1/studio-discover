--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it

const NevermoreRegistry = ServerScriptService.StudioDiscover.Libraries.NevermoreRegistry
const layoutPackages = require(NevermoreRegistry.layoutPackages)
const types = require(NevermoreRegistry.types)

-- A placement reduced to package ids, so a layout compares as plain data.
type Shape = { [string]: { id: string, children: Shape } }

-- Builds a graph from "name@version" ids to the ids each depends on.
const function graph(edges: { [string]: { string } }): { [string]: types.NevermoreResolvedPackage }
	const resolved: { [string]: types.NevermoreResolvedPackage } = {}
	for id, dependencyIds in edges do
		const name, version = id:match("^(.+)@([^@]+)$")
		assert(name ~= nil and version ~= nil, "expected name@version")

		const dependencies = {}
		for _, dependencyId in dependencyIds do
			table.insert(
				dependencies,
				{ alias = dependencyId:match("^(.+)@") or dependencyId, packageId = dependencyId }
			)
		end

		resolved[id] = { packageId = id, name = name, version = version, dependencies = dependencies }
	end

	return resolved
end

const function shape(placements: { [string]: types.Placement }): Shape
	const result: Shape = {}
	for name, placement in placements do
		result[name] = { id = placement.packageId, children = shape(placement.children) }
	end

	return result
end

describe("layoutPackages", function()
	it("hoists a dependency two roots share to the top", function()
		const placements, failures = layoutPackages(
			graph({
				["@q/blend@1.0.0"] = { "@q/maid@1.0.0" },
				["@q/rx@1.0.0"] = { "@q/maid@1.0.0" },
				["@q/maid@1.0.0"] = {},
			}),
			{ "@q/blend@1.0.0", "@q/rx@1.0.0" }
		)

		expect(failures).toEqual({})
		expect(shape(placements)).toEqual({
			["@q/blend"] = { id = "@q/blend@1.0.0", children = {} },
			["@q/rx"] = { id = "@q/rx@1.0.0", children = {} },
			["@q/maid"] = { id = "@q/maid@1.0.0", children = {} },
		})
	end)

	it("nests a version that conflicts with the one at the top in the package that needs it", function()
		const placements = layoutPackages(
			graph({
				["@q/blend@1.0.0"] = { "@q/maid@2.0.0" },
				["@q/rx@1.0.0"] = { "@q/maid@1.0.0" },
				["@q/maid@1.0.0"] = {},
				["@q/maid@2.0.0"] = {},
			}),
			{ "@q/blend@1.0.0", "@q/rx@1.0.0" }
		)

		-- blend lays out first, so its maid takes the top and rx's nests.
		expect(shape(placements)).toEqual({
			["@q/blend"] = { id = "@q/blend@1.0.0", children = {} },
			["@q/maid"] = { id = "@q/maid@2.0.0", children = {} },
			["@q/rx"] = {
				id = "@q/rx@1.0.0",
				children = { ["@q/maid"] = { id = "@q/maid@1.0.0", children = {} } },
			},
		})
	end)

	it("keeps a root at the top over a dependency on another version of it", function()
		const placements = layoutPackages(
			graph({
				["@q/maid@2.0.0"] = {},
				["@q/rx@1.0.0"] = { "@q/maid@1.0.0" },
				["@q/maid@1.0.0"] = {},
			}),
			{ "@q/rx@1.0.0", "@q/maid@2.0.0" }
		)

		expect(shape(placements)).toEqual({
			["@q/maid"] = { id = "@q/maid@2.0.0", children = {} },
			["@q/rx"] = {
				id = "@q/rx@1.0.0",
				children = { ["@q/maid"] = { id = "@q/maid@1.0.0", children = {} } },
			},
		})
	end)

	it("shares a version a nested package finds above it instead of nesting it again", function()
		const placements = layoutPackages(
			graph({
				["@q/blend@1.0.0"] = { "@q/maid@2.0.0" },
				["@q/rx@1.0.0"] = { "@q/maid@1.0.0", "@q/signal@1.0.0" },
				["@q/signal@1.0.0"] = { "@q/maid@1.0.0" },
				["@q/maid@1.0.0"] = {},
				["@q/maid@2.0.0"] = {},
			}),
			{ "@q/blend@1.0.0", "@q/rx@1.0.0" }
		)

		-- signal sits at the top, where maid is 2.0.0, so it gets its own 1.0.0.
		expect(shape(placements)).toEqual({
			["@q/blend"] = { id = "@q/blend@1.0.0", children = {} },
			["@q/maid"] = { id = "@q/maid@2.0.0", children = {} },
			["@q/rx"] = {
				id = "@q/rx@1.0.0",
				children = { ["@q/maid"] = { id = "@q/maid@1.0.0", children = {} } },
			},
			["@q/signal"] = {
				id = "@q/signal@1.0.0",
				children = { ["@q/maid"] = { id = "@q/maid@1.0.0", children = {} } },
			},
		})
	end)

	it("settles a dependency cycle between packages", function()
		const placements, failures = layoutPackages(
			graph({
				["@q/a@1.0.0"] = { "@q/b@1.0.0" },
				["@q/b@1.0.0"] = { "@q/a@1.0.0" },
			}),
			{ "@q/a@1.0.0" }
		)

		expect(failures).toEqual({})
		expect(shape(placements)).toEqual({
			["@q/a"] = { id = "@q/a@1.0.0", children = {} },
			["@q/b"] = { id = "@q/b@1.0.0", children = {} },
		})
	end)
end)
