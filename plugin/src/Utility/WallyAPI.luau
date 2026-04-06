local HttpService = game:GetService("HttpService")

local WALLY_SEARCH_API = "https://api.wally.run/v1/package-search?query="
local WALLY_METADATA_API = "https://api.wally.run/v1/package-metadata/"

local CACHE_TTL = 300

local WallyAPI = {}

local cache: { [string]: { data: any, time: number } } = {}

local function wallyGet(url: string)
	local ok, result = pcall(function()
		return HttpService:GetAsync(url)
	end)
	if not ok then
		return nil, result
	end
	local decodeOk, data = pcall(function()
		return HttpService:JSONDecode(result)
	end)
	if not decodeOk then
		return nil, "Failed to parse response"
	end
	return data, nil
end

local function cachedGet(url: string)
	local entry = cache[url]
	if entry and (os.clock() - entry.time) < CACHE_TTL then
		return entry.data, nil
	end
	local data, err = wallyGet(url)
	if data then
		cache[url] = { data = data, time = os.clock() }
	end
	return data, err
end

local function formatQuery(query: string): string
	local trimmed = string.gsub(query, "^%s+", "")
	return string.gsub(trimmed, "%s+", "+")
end

function WallyAPI.search(query: string)
	return cachedGet(`{WALLY_SEARCH_API}{formatQuery(query)}`)
end

function WallyAPI.metadata(scope: string, name: string)
	return cachedGet(`{WALLY_METADATA_API}{scope}/{name}`)
end

return WallyAPI
