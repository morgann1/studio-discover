--!strict

local HttpService = game:GetService("HttpService")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local buildUserAgent = require(StudioDiscover.Source.Api.buildUserAgent)
local cache = require(StudioDiscover.Source.Api.cache)
local createLogger = require(StudioDiscover.Source.Util.createLogger)
local types = require(StudioDiscover.Source.Api.types)

local logger = createLogger.createLogger("api.pesdeMetadata")

local API_BASE = "https://registry.Pesde.daimond113.com/v1"

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
			dependencies = {},
			["server-dependencies"] = {},
			["dev-dependencies"] = {},
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
