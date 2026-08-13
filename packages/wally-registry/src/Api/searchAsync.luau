--!strict

local HttpService = game:GetService("HttpService")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local cache = require(StudioDiscover.Core.cache)
local httpClient = require(StudioDiscover.WallyRegistry.Api.httpClient)
local types = require(StudioDiscover.WallyRegistry.types)

local MIN_QUERY_LENGTH = 2

local function formEncode(value: string): string
	return (HttpService:UrlEncode(value):gsub("%%20", "+"))
end

local function searchPackagesAsync(query: string): ({ types.WallyPackageBrief }?, string?)
	if #query < MIN_QUERY_LENGTH then
		return {}, nil
	end

	local path = `/package-search?query={formEncode(query)}`

	local cached = cache.get(path)
	if cached ~= nil then
		return cached, nil
	end

	local body, err = httpClient.requestAsync(path)
	if body == nil then
		return nil, err
	end

	local success, decoded = pcall(function()
		return HttpService:JSONDecode(body)
	end)
	if not success then
		return nil, `JSON decode failed: {decoded}`
	end

	cache.set(path, decoded)
	return decoded, nil
end

return searchPackagesAsync
