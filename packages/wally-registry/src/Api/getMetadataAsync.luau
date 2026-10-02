--!strict

const HttpService = game:GetService("HttpService")

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const asString = require(StudioDiscover.Libraries.Core.asString)
const asStringList = require(StudioDiscover.Libraries.Core.asStringList)
const asStringMap = require(StudioDiscover.Libraries.Core.asStringMap)
const asTable = require(StudioDiscover.Libraries.Core.asTable)
const createCache = require(StudioDiscover.Libraries.Core.createCache)
const httpClient = require(StudioDiscover.Libraries.WallyRegistry.Api.httpClient)
const isNewerVersion = require(StudioDiscover.Libraries.Semver.isNewerVersion)
const types = require(StudioDiscover.Libraries.Core.types)

const cache = createCache<<types.PackageMetadata>>()

-- Reads one version out of Wally's response, or returns nil when it lacks a version or realm.
const function readPackageVersion(raw: unknown): types.PackageVersion?
	const versionData = asTable(raw)
	const info = if versionData ~= nil then asTable(versionData.package) else nil
	if versionData == nil or info == nil then
		return nil
	end

	const version, realm = asString(info.version), asString(info.realm)
	if version == nil or realm == nil then
		return nil
	end

	return {
		package = {
			authors = asStringList(info.authors),
			description = asString(info.description),
			license = asString(info.license),
			realm = realm,
			version = version,
		},
		dependencies = asStringMap(versionData.dependencies),
		["server-dependencies"] = asStringMap(versionData["server-dependencies"]),
		["dev-dependencies"] = asStringMap(versionData["dev-dependencies"]),
	}
end

--[[
	Fetches every published version of a package, newest first, or returns nil and
		why not. A version the response does not describe fully is left out.
]]
const function getMetadataAsync(scope: string, name: string): (types.PackageMetadata?, string?)
	const path = `/package-metadata/{HttpService:UrlEncode(scope)}/{HttpService:UrlEncode(name)}`

	const cached = cache.get(path)
	if cached ~= nil then
		return cached, nil
	end

	const decoded, err = httpClient.getJsonAsync(path)
	if err ~= nil then
		return nil, err
	end

	const response = asTable(decoded)
	const versions: { types.PackageVersion } = {}
	for _, rawVersion in asTable(if response ~= nil then response.versions else nil) or {} do
		const version = readPackageVersion(rawVersion)
		if version ~= nil then
			table.insert(versions, version)
		end
	end

	if #versions == 0 then
		return nil, "metadata has no versions"
	end

	table.sort(versions, function(a: types.PackageVersion, b: types.PackageVersion): boolean
		return isNewerVersion(a.package.version, b.package.version)
	end)

	const metadata: types.PackageMetadata = { versions = versions }
	cache.set(path, metadata)
	return metadata, nil
end

return getMetadataAsync
