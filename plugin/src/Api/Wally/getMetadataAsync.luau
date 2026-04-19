--!strict

local HttpService = game:GetService("HttpService")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local cache = require(StudioDiscover.Source.Api.cache)
local httpClient = require(StudioDiscover.Source.Api.Wally.httpClient)
local types = require(StudioDiscover.Source.Api.types)

local function getPackageMetadataAsync(scope: string, name: string): (types.WallyPackageMetadata?, string?)
	local path = `/package-metadata/{HttpService:UrlEncode(scope)}/{HttpService:UrlEncode(name)}`

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

return getPackageMetadataAsync
