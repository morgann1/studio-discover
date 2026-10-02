--!strict

const HttpService = game:GetService("HttpService")

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const asString = require(StudioDiscover.Libraries.Core.asString)
const asStringList = require(StudioDiscover.Libraries.Core.asStringList)
const asTable = require(StudioDiscover.Libraries.Core.asTable)
const createCache = require(StudioDiscover.Libraries.Core.createCache)
const httpClient = require(StudioDiscover.Libraries.WallyRegistry.Api.httpClient)
const types = require(StudioDiscover.Libraries.Core.types)

const MIN_QUERY_LENGTH = 2

const cache = createCache() :: createCache.Cache<{ types.PackageBrief }>

const function formEncode(value: string): string
	return (HttpService:UrlEncode(value):gsub("%%20", "+"))
end

const function readBrief(raw: unknown): types.PackageBrief?
	const entry = asTable(raw)
	if entry == nil then
		return nil
	end

	const scope, name = asString(entry.scope), asString(entry.name)
	if scope == nil or name == nil then
		return nil
	end

	return {
		registries = { "wally" },
		scope = scope,
		name = name,
		description = asString(entry.description),
		latestVersion = asStringList(entry.versions)[1],
	}
end

--[[
	Searches Wally for packages matching `query`, or returns nil and why not. A query
		shorter than two characters matches nothing, without a request.
]]
const function searchAsync(query: string): ({ types.PackageBrief }?, string?)
	if #query < MIN_QUERY_LENGTH then
		return {}, nil
	end

	const path = `/package-search?query={formEncode(query)}`

	const cached = cache.get(path)
	if cached ~= nil then
		return cached, nil
	end

	const decoded, err = httpClient.getJsonAsync(path)
	if err ~= nil then
		return nil, err
	end

	const results: { types.PackageBrief } = {}
	for _, rawEntry in asTable(decoded) or {} do
		const brief = readBrief(rawEntry)
		if brief ~= nil then
			table.insert(results, brief)
		end
	end

	cache.set(path, results)
	return results, nil
end

return searchAsync
