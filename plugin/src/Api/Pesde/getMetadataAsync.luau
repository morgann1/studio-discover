--!strict

local HttpService = game:GetService("HttpService")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local buildUserAgent = require(StudioDiscover.Source.Api.buildUserAgent)
local cache = require(StudioDiscover.Source.Api.cache)
local createLogger = require(StudioDiscover.Source.Util.createLogger)
local rateLimiter = require(StudioDiscover.Source.Api.Pesde.rateLimiter)
local types = require(StudioDiscover.Source.Api.types)

local logger = createLogger.createLogger("pesde.api.metadata")

local API_BASE = "https://registry.pesde.daimond113.com/v1"

type Realm = "shared" | "server"

local function selectRobloxTarget(targets: any): (string?, any)
	if typeof(targets) ~= "table" then
		return nil, nil
	end
	local robloxTarget = targets.roblox
	if robloxTarget ~= nil then
		return "roblox", robloxTarget
	end
	local serverTarget = targets.roblox_server
	if serverTarget ~= nil then
		return "roblox_server", serverTarget
	end
	return nil, nil
end

local function formatDepValue(info: any): string?
	if typeof(info) ~= "table" then
		return nil
	end
	local version = info.version
	if typeof(version) ~= "string" then
		return nil
	end
	local path: string? = if typeof(info.name) == "string"
		then info.name
		elseif typeof(info.wally) == "string" then info.wally
		else nil
	if path == nil then
		return nil
	end
	return `{path}@{version}`
end

local function extractDeps(rawDeps: any): (types.WallyDependencyMap, types.WallyDependencyMap, types.WallyDependencyMap)
	local standard: types.WallyDependencyMap = {}
	local peer: types.WallyDependencyMap = {}
	local dev: types.WallyDependencyMap = {}
	if typeof(rawDeps) ~= "table" then
		return standard, peer, dev
	end
	for alias, entry in rawDeps do
		if typeof(entry) ~= "table" then
			continue
		end
		local info = entry[1]
		local kind = entry[2]
		local formatted = formatDepValue(info)
		if formatted == nil then
			continue
		end
		if kind == "dev" then
			dev[alias] = formatted
		elseif kind == "peer" then
			peer[alias] = formatted
		else
			standard[alias] = formatted
		end
	end
	return standard, peer, dev
end

local function toWallyShape(rawName: string, rawVersions: any): types.WallyPackageMetadata?
	local _, name = rawName:match("^(.+)/(.+)$")
	if name == nil then
		return nil
	end

	local versionKeys: { string } = {}
	for versionKey in rawVersions do
		table.insert(versionKeys, versionKey)
	end

	table.sort(versionKeys, function(a, b)
		return a > b
	end)

	local versions: { types.WallyPackageVersion } = {}
	for _, versionKey in versionKeys do
		local versionData = rawVersions[versionKey]
		local targetKind, target = selectRobloxTarget(versionData.targets)
		if target == nil then
			continue
		end

		local realm: Realm = if targetKind == "roblox_server" then "server" else "shared"
		local standard, peer, dev = extractDeps(target.dependencies)
		for alias, value in peer do
			if standard[alias] == nil then
				standard[alias] = value
			end
		end

		local sharedDeps: types.WallyDependencyMap = if realm == "shared" then standard else {}
		local serverDeps: types.WallyDependencyMap = if realm == "server" then standard else {}

		table.insert(versions, {
			package = {
				authors = target.authors or {},
				description = versionData.description,
				license = target.license,
				name = name,
				realm = realm,
				registry = "pesde",
				version = versionKey,
				homepage = nil,
				repository = target.repository,
			},
			place = {
				["shared-packages"] = nil,
				["server-packages"] = nil,
			},
			dependencies = sharedDeps,
			["server-dependencies"] = serverDeps,
			["dev-dependencies"] = dev,
		})
	end

	if #versions == 0 then
		return nil
	end

	return { versions = versions }
end

local function getPesdeMetadataAsync(scope: string, name: string): (types.WallyPackageMetadata?, string?)
	local slug = HttpService:UrlEncode(`{scope}/{name}`)
	local path = `/packages/{slug}`
	local cacheKey = `pesde:{path}`

	local cached = cache.get(cacheKey)
	if cached ~= nil then
		return cached, nil
	end

	rateLimiter.acquireAsync()
	local ok, response = pcall(function()
		return HttpService:RequestAsync({
			Url = `{API_BASE}{path}`,
			Method = "GET",
			Headers = {
				["X-Real-User-Agent"] = buildUserAgent(),
			},
		})
	end)
	if not ok then
		logger.warn(`request failed: {response}`)
		return nil, tostring(response)
	end
	if response.StatusCode < 200 or response.StatusCode >= 300 then
		logger.warn(`HTTP {response.StatusCode}`)
		return nil, `HTTP {response.StatusCode}`
	end

	local decodeOk, decoded = pcall(function()
		return HttpService:JSONDecode(response.Body)
	end)
	if not decodeOk then
		return nil, `JSON decode failed: {decoded}`
	end

	local raw = decoded :: any
	local metadata = toWallyShape(raw.name or `{scope}/{name}`, raw.versions)
	if metadata == nil then
		return nil, "No Roblox-compatible versions found"
	end

	cache.set(cacheKey, metadata)
	logger.info(`{scope}/{name}: {#metadata.versions} Roblox-compatible version(s)`)
	return metadata, nil
end

return getPesdeMetadataAsync
