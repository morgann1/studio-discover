--!strict

const HttpService = game:GetService("HttpService")

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const asString = require(StudioDiscover.Libraries.Core.asString)
const asStringList = require(StudioDiscover.Libraries.Core.asStringList)
const asTable = require(StudioDiscover.Libraries.Core.asTable)
const createCache = require(StudioDiscover.Libraries.Core.createCache)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const httpClient = require(StudioDiscover.Libraries.PesdeRegistry.Api.httpClient)
const types = require(StudioDiscover.Libraries.PesdeRegistry.types)

const logger = createLogger.createLogger("pesde.api.metadata")

export type DependencyType = "standard" | "peer" | "dev"

-- One dependency of a published version.
export type DependencySpec = {
	read alias: string,
	read kind: types.Kind,
	read name: string,
	read versionReq: string,
	read target: types.Target?,
	read ty: DependencyType,
}

-- One version published for one target. A version published for both targets is two entries.
export type VersionEntry = {
	read version: string,
	read target: types.Target,
	read libPath: string?,
	read dependencies: { DependencySpec },
	read description: string?,
	read authors: { string },
	read license: string?,
}

export type PesdeMetadata = {
	read versions: { VersionEntry },
}

const cache = createCache() :: createCache.Cache<PesdeMetadata>

const function parseTarget(raw: unknown): types.Target?
	if raw == "roblox" or raw == "roblox_server" then
		return raw
	end

	return nil
end

-- Reads one `[info, kind]` dependency entry, or returns nil when it is malformed.
const function parseDependency(alias: string, raw: unknown): DependencySpec?
	const entry = asTable(raw)
	const info = if entry ~= nil then asTable(entry[1]) else nil
	if entry == nil or info == nil then
		return nil
	end

	const versionReq = asString(info.version)
	if versionReq == nil then
		return nil
	end

	const rawType = entry[2]
	const ty: DependencyType = if rawType == "peer" then "peer" elseif rawType == "dev" then "dev" else "standard"

	const pesdeName, wallyName = asString(info.name), asString(info.wally)
	if pesdeName ~= nil then
		return {
			alias = alias,
			kind = "pesde",
			name = pesdeName,
			versionReq = versionReq,
			target = parseTarget(info.target),
			ty = ty,
		}
	elseif wallyName ~= nil then
		return {
			alias = alias,
			kind = "wally",
			name = wallyName,
			versionReq = versionReq,
			target = nil,
			ty = ty,
		}
	end

	return nil
end

const function parseVersion(version: string, raw: unknown): { VersionEntry }
	const entries: { VersionEntry } = {}
	const versionData = asTable(raw)
	if versionData == nil then
		return entries
	end

	for targetName, rawTarget in asTable(versionData.targets) or {} do
		const target = parseTarget(targetName)
		const targetData = asTable(rawTarget)
		if target == nil or targetData == nil then
			continue
		end

		const manifestTarget = asTable(targetData.target)

		const dependencies: { DependencySpec } = {}
		for alias, rawDependency in asTable(targetData.dependencies) or {} do
			const dependency = if typeof(alias) == "string" then parseDependency(alias, rawDependency) else nil
			if dependency ~= nil then
				table.insert(dependencies, dependency)
			end
		end

		table.insert(entries, {
			version = version,
			target = target,
			libPath = if manifestTarget ~= nil then asString(manifestTarget.lib) else nil,
			dependencies = dependencies,
			description = asString(versionData.description),
			authors = asStringList(targetData.authors),
			license = asString(targetData.license),
		})
	end

	return entries
end

--[[
	Fetches every version and target a package is published for, or returns nil
		and why not. Resolve reads it directly, and the package screen reads it
		through `Api.getMetadataAsync`.
]]
const function fetchMetadataAsync(scope: string, name: string): (PesdeMetadata?, string?)
	const path = `/packages/{HttpService:UrlEncode(`{scope}/{name}`)}`

	const cached = cache.get(path)
	if cached ~= nil then
		return cached, nil
	end

	const decoded, err = httpClient.getJsonAsync(path)
	if err ~= nil then
		return nil, err
	end

	const response = asTable(decoded)
	const rawVersions = if response ~= nil then asTable(response.versions) else nil
	if rawVersions == nil then
		return nil, "metadata missing versions"
	end

	const versions: { VersionEntry } = {}
	for version, rawVersion in rawVersions do
		if typeof(version) ~= "string" then
			continue
		end

		const entries = parseVersion(version, rawVersion)
		table.move(entries, 1, #entries, #versions + 1, versions)
	end

	const metadata: PesdeMetadata = { versions = versions }

	cache.set(path, metadata)
	logger.info(`{scope}/{name}: {#versions} version/target pair(s)`)
	return metadata, nil
end

return fetchMetadataAsync
