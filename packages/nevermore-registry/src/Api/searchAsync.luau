--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const fetchCatalogAsync = require(StudioDiscover.Libraries.NevermoreRegistry.Api.fetchCatalogAsync)
const types = require(StudioDiscover.Libraries.Core.types)

-- How well a package matches a lowercase query: 1 for its name, 2 for part of its name, 3 for its description, or nil.
const function rank(brief: types.PackageBrief, needle: string): number?
	const name = string.lower(brief.name)
	if name == needle then
		return 1
	elseif string.find(name, needle, 1, true) ~= nil then
		return 2
	elseif brief.description ~= nil and string.find(string.lower(brief.description), needle, 1, true) ~= nil then
		return 3
	end

	return nil
end

--[[
	Searches the Nevermore catalog for `query`, or returns nil and why not. An exact
		name comes first, then names that contain the query, then descriptions that
		do, each in name order. An empty query lists the whole catalog.
]]
const function searchAsync(query: string): ({ types.PackageBrief }?, string?)
	const catalog, err = fetchCatalogAsync()
	if catalog == nil then
		return nil, err
	end

	const needle = string.lower(query)
	if needle == "" then
		return catalog, nil
	end

	const ranks: { [types.PackageBrief]: number } = {}
	const results: { types.PackageBrief } = {}
	for _, brief in catalog do
		const briefRank = rank(brief, needle)
		if briefRank ~= nil then
			ranks[brief] = briefRank
			table.insert(results, brief)
		end
	end

	table.sort(results, function(a: types.PackageBrief, b: types.PackageBrief)
		if ranks[a] ~= ranks[b] then
			return ranks[a] < ranks[b]
		end

		return a.name < b.name
	end)

	return results, nil
end

return searchAsync
