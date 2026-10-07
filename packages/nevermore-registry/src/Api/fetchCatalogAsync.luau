--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const asString = require(StudioDiscover.Libraries.Core.asString)
const asStringList = require(StudioDiscover.Libraries.Core.asStringList)
const asTable = require(StudioDiscover.Libraries.Core.asTable)
const createCache = require(StudioDiscover.Libraries.Core.createCache)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const httpClient = require(StudioDiscover.Libraries.NevermoreRegistry.Api.httpClient)
const splitNpmName = require(StudioDiscover.Libraries.NevermoreRegistry.splitNpmName)
const types = require(StudioDiscover.Libraries.Core.types)

const logger = createLogger.createLogger("nevermore.api.catalog")

-- The npm accounts that publish Nevermore, and the scope each publishes under.
const PUBLISHERS = table.freeze({
	{ maintainer = "quenty", scope = "quenty" },
	{ maintainer = "quentystudios", scope = "quentystudios" },
})

-- The most results npm's search returns at once.
const PAGE_SIZE = 250

const cache = createCache<<{ types.PackageBrief }>>()

--[[
	Whether a search result is a package for Roblox. Quenty also publishes the
		Nevermore CLI and its Node helpers, which leave "Lua" out of their keywords.
		The quentystudios packages carry no keywords, and all of them are for Roblox.
]]
const function isRobloxPackage(scope: string, keywords: { string }): boolean
	if scope == "quentystudios" then
		return true
	end

	for _, keyword in keywords do
		if string.lower(keyword) == "lua" then
			return true
		end
	end

	return false
end

const function readBrief(rawObject: unknown, publisherScope: string): types.PackageBrief?
	const object = asTable(rawObject)
	const package = if object ~= nil then asTable(object.package) else nil
	if package == nil then
		return nil
	end

	const fullName = asString(package.name)
	if fullName == nil then
		return nil
	end

	const scope, name = splitNpmName(fullName)
	if scope == nil or name == nil then
		return nil
	elseif scope ~= publisherScope or not isRobloxPackage(scope, asStringList(package.keywords)) then
		return nil
	end

	return {
		registries = { "nevermore" },
		scope = scope,
		name = name,
		description = asString(package.description),
		latestVersion = asString(package.version),
	}
end

-- Every Roblox package one publisher has on npm, a page at a time, or nil and why not.
const function fetchPublisherAsync(maintainer: string, scope: string): ({ types.PackageBrief }?, string?)
	const briefs: { types.PackageBrief } = {}
	local from = 0

	while true do
		const path = `/-/v1/search?text=maintainer:{maintainer}&size={PAGE_SIZE}&from={from}`
		const decoded, err = httpClient.getJsonAsync(path)
		if err ~= nil then
			return nil, err
		end

		const response = asTable(decoded)
		const objects = if response ~= nil then asTable(response.objects) else nil
		if objects == nil then
			return nil, "search response missing objects"
		end

		local pageCount = 0
		for _, rawObject in objects do
			pageCount += 1

			const brief = readBrief(rawObject, scope)
			if brief ~= nil then
				table.insert(briefs, brief)
			end
		end

		from += PAGE_SIZE
		const total = if response ~= nil then tonumber(response.total) else nil
		if pageCount < PAGE_SIZE or total == nil or from >= total then
			return briefs, nil
		end
	end
end

--[[
	Fetches every Nevermore package for Roblox, sorted by name, or returns nil and
		why not. npm has no listing of a scope, so this searches by the accounts that
		publish Nevermore and keeps what they publish under its scopes.
]]
const function fetchCatalogAsync(): ({ types.PackageBrief }?, string?)
	const cached = cache.get("catalog")
	if cached ~= nil then
		return cached, nil
	end

	const catalog: { types.PackageBrief } = {}
	for _, publisher in PUBLISHERS do
		const briefs, err = fetchPublisherAsync(publisher.maintainer, publisher.scope)
		if briefs == nil then
			return nil, err
		end

		table.move(briefs, 1, #briefs, #catalog + 1, catalog)
	end

	table.sort(catalog, function(a: types.PackageBrief, b: types.PackageBrief)
		return a.name < b.name
	end)

	cache.set("catalog", catalog)
	logger.info(`catalog has {#catalog} package(s)`)
	return catalog, nil
end

return fetchCatalogAsync
