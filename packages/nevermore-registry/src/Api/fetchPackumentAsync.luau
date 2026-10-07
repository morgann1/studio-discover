--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const asString = require(StudioDiscover.Libraries.Core.asString)
const asStringMap = require(StudioDiscover.Libraries.Core.asStringMap)
const asTable = require(StudioDiscover.Libraries.Core.asTable)
const createCache = require(StudioDiscover.Libraries.Core.createCache)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const httpClient = require(StudioDiscover.Libraries.NevermoreRegistry.Api.httpClient)
const packagePath = require(StudioDiscover.Libraries.NevermoreRegistry.Api.packagePath)

const logger = createLogger.createLogger("nevermore.api.packument")

-- One published version and its dependencies, by npm name to range.
export type VersionEntry = {
	read version: string,
	read dependencies: { [string]: string },
}

-- Every version of a package, in no order, and the version its `latest` tag points at.
export type Packument = {
	read versions: { VersionEntry },
	read latest: string?,
}

-- npm's abbreviated document, which leaves out readmes and the rest of each package.json.
const ABBREVIATED = { ["Accept"] = "application/vnd.npm.install-v1+json" }

const cache = createCache<<Packument>>()

--[[
	Fetches every version a package has published, or returns nil and why not. The
		third value is true when npm doesn't have the package.
]]
const function fetchPackumentAsync(name: string): (Packument?, string?, boolean)
	const path = packagePath(name)

	const cached = cache.get(path)
	if cached ~= nil then
		return cached, nil, false
	end

	const decoded, err, missing = httpClient.getJsonAsync(path, ABBREVIATED)
	if err ~= nil then
		return nil, err, missing
	end

	const document = asTable(decoded)
	const rawVersions = if document ~= nil then asTable(document.versions) else nil
	if document == nil or rawVersions == nil then
		return nil, "package document missing versions", false
	end

	const versions: { VersionEntry } = {}
	for version, rawVersion in rawVersions do
		const entry = asTable(rawVersion)
		if typeof(version) ~= "string" or entry == nil then
			continue
		end

		table.insert(versions, {
			version = version,
			dependencies = asStringMap(entry.dependencies),
		})
	end

	const distTags = asTable(document["dist-tags"])
	const packument: Packument = {
		versions = versions,
		latest = if distTags ~= nil then asString(distTags.latest) else nil,
	}

	cache.set(path, packument)
	logger.info(`{name}: {#versions} version(s)`)
	return packument, nil, false
end

return fetchPackumentAsync
