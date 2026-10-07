--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerScriptService = game:GetService("ServerScriptService")

const JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
const describe = JestGlobals.describe
const expect = JestGlobals.expect
const it = JestGlobals.it
const jest = JestGlobals.jest

const NevermoreRegistry = ServerScriptService.StudioDiscover.Libraries.NevermoreRegistry

const function brief(name: string, description: string?)
	return { registries = { "nevermore" }, scope = "quenty", name = name, description = description }
end

-- The catalog in name order, as `fetchCatalogAsync` returns it.
const CATALOG = {
	brief("baseobject", "BaseObject implementation with Maid attached"),
	brief("maid", "Easily cleanup event listeners"),
	brief("maidtaskutils", "Utility methods for maid tasks"),
	brief("rx", "Reactive extensions"),
}

jest.mock(NevermoreRegistry.Api.fetchCatalogAsync, function()
	return function()
		return CATALOG, nil
	end
end)

const searchAsync = require(NevermoreRegistry.Api.searchAsync)

const function namesFor(query: string): { string }
	const results = searchAsync(query)
	assert(results ~= nil, "expected results")

	const names = {}
	for _, result in results do
		table.insert(names, result.name)
	end

	return names
end

describe("searchAsync", function()
	it("puts the exact name first, then names containing the query, then descriptions", function()
		expect(namesFor("Maid")).toEqual({ "maid", "maidtaskutils", "baseobject" })
	end)

	it("lists the whole catalog for an empty query", function()
		expect(namesFor("")).toEqual({ "baseobject", "maid", "maidtaskutils", "rx" })
	end)
end)
