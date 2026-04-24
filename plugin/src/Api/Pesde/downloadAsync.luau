--!strict

local HttpService = game:GetService("HttpService")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local buildUserAgent = require(StudioDiscover.Source.Api.buildUserAgent)
local cache = require(StudioDiscover.Source.Api.cache)
local createLogger = require(StudioDiscover.Source.Util.createLogger)
local rateLimiter = require(StudioDiscover.Source.Api.Pesde.rateLimiter)

local logger = createLogger.createLogger("pesde.api.download")

local API_BASE = "https://registry.pesde.daimond113.com/v1"

type Target = "roblox" | "roblox_server"

local function downloadPesdeAsync(scope: string, name: string, version: string, target: Target): (string?, string?)
	local cacheKey = `pesde:archive:{scope}/{name}@{version}/{target}`
	local cached = cache.get(cacheKey)
	if cached ~= nil then
		return cached, nil
	end

	local slug = HttpService:UrlEncode(`{scope}/{name}`)
	local encodedVersion = HttpService:UrlEncode(version)
	local encodedTarget = HttpService:UrlEncode(target)
	local url = `{API_BASE}/packages/{slug}/{encodedVersion}/{encodedTarget}/archive`

	rateLimiter.acquireAsync()
	local ok, response = pcall(function()
		return HttpService:RequestAsync({
			Url = url,
			Method = "GET",
			Headers = {
				["Accept"] = "application/octet-stream",
				["X-Real-User-Agent"] = buildUserAgent(),
			},
		})
	end)
	if not ok then
		logger.warn(`request failed for {scope}/{name}@{version} {target}: {response}`)
		return nil, tostring(response)
	end
	if response.StatusCode < 200 or response.StatusCode >= 300 then
		logger.warn(`HTTP {response.StatusCode} for {scope}/{name}@{version} {target}`)
		return nil, `HTTP {response.StatusCode}`
	end
	if response.Body == nil or response.Body == "" then
		return nil, "Empty response"
	end

	cache.set(cacheKey, response.Body)
	logger.info(`downloaded {scope}/{name}@{version} {target} ({#response.Body} bytes)`)
	return response.Body, nil
end

return downloadPesdeAsync
