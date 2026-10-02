--!strict

const HttpService = game:GetService("HttpService")

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const asString = require(StudioDiscover.Core.asString)
const asTable = require(StudioDiscover.Core.asTable)
const createCache = require(StudioDiscover.Core.createCache)
const createLogger = require(StudioDiscover.Core.createLogger)
const httpClient = require(StudioDiscover.PesdeRegistry.Api.httpClient)
const splitFullName = require(StudioDiscover.Core.splitFullName)
const types = require(StudioDiscover.Core.types)

const logger = createLogger.createLogger("pesde.api.search")

const cache = createCache() :: createCache.Cache<{ types.PackageBrief }>

const function hasRobloxTarget(targets: unknown): boolean
	for _, rawTarget in asTable(targets) or {} do
		const target = asTable(rawTarget)
		const kind = if target ~= nil then target.kind else nil
		if kind == "roblox" or kind == "roblox_server" then
			return true
		end
	end

	return false
end

const function readBrief(rawEntry: unknown): types.PackageBrief?
	const entry = asTable(rawEntry)
	if entry == nil or not hasRobloxTarget(entry.targets) then
		return nil
	end

	const fullName = asString(entry.name)
	if fullName == nil then
		return nil
	end

	const scope, name = splitFullName(fullName)
	if scope == nil or name == nil then
		return nil
	end

	return {
		registries = { "pesde" },
		scope = scope,
		name = name,
		description = asString(entry.description),
		latestVersion = asString(entry.version),
	}
end

-- Searches pesde for packages with a Roblox target matching `query`, or returns nil and why not.
const function searchAsync(query: string): ({ types.PackageBrief }?, string?)
	const path = `/search?query={HttpService:UrlEncode(query)}&offset=0`

	const cached = cache.get(path)
	if cached ~= nil then
		return cached, nil
	end

	const decoded, err = httpClient.getJsonAsync(path)
	if err ~= nil then
		return nil, err
	end

	const response = asTable(decoded)
	const data = if response ~= nil then asTable(response.data) else nil
	if data == nil then
		logger.warn("response missing `data` array")
		return {}, nil
	end

	const results: { types.PackageBrief } = {}
	for _, rawEntry in data do
		const brief = readBrief(rawEntry)
		if brief ~= nil then
			table.insert(results, brief)
		end
	end

	logger.info(`"{query}" -> {#results} Roblox result(s)`)
	cache.set(path, results)
	return results, nil
end

return searchAsync
