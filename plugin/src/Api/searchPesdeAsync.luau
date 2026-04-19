--!strict

local HttpService = game:GetService("HttpService")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local createLogger = require(StudioDiscover.Source.Util.createLogger)
local types = require(StudioDiscover.Source.Api.types)

local logger = createLogger.createLogger("api.pesdeSearch")

local API_BASE = "https://registry.pesde.daimond113.com/v1"

-- Studio can't run Lune/Luau-only packages, so non-Roblox targets are
-- filtered out before any result leaves this module.
local function hasRobloxTarget(targets: any): boolean
	if typeof(targets) ~= "table" then
		return false
	end
	for _, target in targets do
		local kind = target.kind
		if kind == "roblox" or kind == "roblox_server" then
			return true
		end
	end
	return false
end

local function searchPesdeAsync(query: string): ({ types.PackageBrief }?, string?)
	local url = `{API_BASE}/search?query={HttpService:UrlEncode(query)}&offset=0`

	local success, response = pcall(function()
		return HttpService:RequestAsync({
			Url = url,
			Method = "GET",
		})
	end)
	if not success then
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

	local data = (decoded :: any).data
	if typeof(data) ~= "table" then
		logger.warn("response missing `data` array")
		return {}, nil
	end

	local results: { types.PackageBrief } = {}
	for _, entry in data do
		if not hasRobloxTarget(entry.targets) then
			continue
		end
		local scope, name = (entry.name :: string):match("^(.+)/(.+)$")
		if scope == nil or name == nil then
			continue
		end
		table.insert(results, {
			registry = "pesde" :: "pesde",
			scope = scope :: string,
			name = name :: string,
			description = entry.description,
			latestVersion = entry.version,
		})
	end

	logger.info(`"{query}" -> {#results} Roblox result(s)`)
	return results, nil
end

return searchPesdeAsync
