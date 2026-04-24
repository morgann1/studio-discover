--!strict

local HttpService = game:GetService("HttpService")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local buildUserAgent = require(StudioDiscover.Source.Api.buildUserAgent)
local cache = require(StudioDiscover.Source.Api.cache)
local createLogger = require(StudioDiscover.Source.Util.createLogger)
local rateLimiter = require(StudioDiscover.Source.Api.Pesde.rateLimiter)

local logger = createLogger.createLogger("pesde.installer.fetchMetadata")

local API_BASE = "https://registry.pesde.daimond113.com/v1"

export type Kind = "pesde" | "wally"
export type DepType = "standard" | "peer" | "dev"
export type Target = "roblox" | "roblox_server"

export type DepSpec = {
	alias: string,
	kind: Kind,
	name: string,
	versionReq: string,
	target: Target?,
	ty: DepType,
}

export type VersionEntry = {
	version: string,
	target: Target,
	libPath: string?,
	dependencies: { DepSpec },
}

export type PesdeMetadata = {
	name: string,
	versions: { VersionEntry },
}

local function parseTarget(raw: any): Target?
	if raw == "roblox" or raw == "roblox_server" then
		return raw :: Target
	end
	return nil
end

local function parseDepSpec(alias: string, entry: any): DepSpec?
	if typeof(entry) ~= "table" then
		return nil
	end
	local info = entry[1]
	local tyRaw = entry[2]
	if typeof(info) ~= "table" then
		return nil
	end
	local version = info.version
	if typeof(version) ~= "string" then
		return nil
	end
	local ty: DepType
	if tyRaw == "peer" then
		ty = "peer"
	elseif tyRaw == "dev" then
		ty = "dev"
	else
		ty = "standard"
	end

	if typeof(info.name) == "string" then
		return {
			alias = alias,
			kind = "pesde",
			name = info.name,
			versionReq = version,
			target = parseTarget(info.target),
			ty = ty,
		}
	elseif typeof(info.wally) == "string" then
		return {
			alias = alias,
			kind = "wally",
			name = info.wally,
			versionReq = version,
			target = nil,
			ty = ty,
		}
	end
	return nil
end

local function parseVersion(versionKey: string, versionData: any): { VersionEntry }
	local results: { VersionEntry } = {}
	if typeof(versionData) ~= "table" or typeof(versionData.targets) ~= "table" then
		return results
	end
	for targetName, targetData in versionData.targets do
		local target = parseTarget(targetName)
		if target == nil then
			continue
		end
		if typeof(targetData) ~= "table" then
			continue
		end
		local libPath: string? = nil
		if typeof(targetData.target) == "table" then
			local lib = targetData.target.lib
			if typeof(lib) == "string" then
				libPath = lib
			end
		end
		local deps: { DepSpec } = {}
		if typeof(targetData.dependencies) == "table" then
			for alias, depEntry in targetData.dependencies do
				local spec = parseDepSpec(alias, depEntry)
				if spec ~= nil then
					table.insert(deps, spec)
				end
			end
		end
		local resolvedTarget: Target = target :: Target
		local entry: VersionEntry = {
			version = versionKey,
			target = resolvedTarget,
			libPath = libPath,
			dependencies = deps,
		}
		table.insert(results, entry)
	end
	return results
end

local function fetchMetadataAsync(scope: string, name: string): (PesdeMetadata?, string?)
	local cacheKey = `pesde:rawmeta:{scope}/{name}`
	local cached = cache.get(cacheKey)
	if cached ~= nil then
		return cached, nil
	end

	local slug = HttpService:UrlEncode(`{scope}/{name}`)
	local url = `{API_BASE}/packages/{slug}`

	rateLimiter.acquireAsync()
	local ok, response = pcall(function()
		return HttpService:RequestAsync({
			Url = url,
			Method = "GET",
			Headers = {
				["X-Real-User-Agent"] = buildUserAgent(),
			},
		})
	end)
	if not ok then
		logger.warn(`request failed for {scope}/{name}: {response}`)
		return nil, tostring(response)
	end
	if response.StatusCode < 200 or response.StatusCode >= 300 then
		return nil, `HTTP {response.StatusCode}`
	end

	local decodeOk, decoded = pcall(function()
		return HttpService:JSONDecode(response.Body)
	end)
	if not decodeOk then
		return nil, `JSON decode failed: {decoded}`
	end

	local raw = decoded :: any
	if typeof(raw.versions) ~= "table" then
		return nil, "metadata missing versions"
	end

	local versions: { VersionEntry } = {}
	for versionKey, versionData in raw.versions do
		for _, entry in parseVersion(versionKey, versionData) do
			table.insert(versions, entry)
		end
	end

	local metadata: PesdeMetadata = {
		name = `{scope}/{name}`,
		versions = versions,
	}

	cache.set(cacheKey, metadata)
	logger.info(`{scope}/{name}: {#versions} version/target pair(s)`)
	return metadata, nil
end

return fetchMetadataAsync
