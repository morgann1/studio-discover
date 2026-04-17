--!strict

local Discover = script:FindFirstAncestor("Discover")

local HttpService = game:GetService("HttpService")
local StudioService = game:GetService("StudioService")

local RateLimiter = require(Discover.Src.Api.RateLimiter)
local StatusPublisher = require(Discover.Src.Api.StatusPublisher)
local Version = require(Discover.Src.Version)

local WALLY_API = "https://api.wally.run"
local CACHE_TTL = 300

export type Status = StatusPublisher.Status

local cache: { [string]: { data: any, time: number }? } = {}

local function userAgent(): string
	return `StudioDiscover/{Version} (+https://github.com/morgann1/studio-discover; StudioUserId={StudioService:GetUserId()})`
end

local function parseRetryAfter(headers: { [string]: string }?): number?
	if headers == nil then
		return nil
	end
	for k, v in headers do
		if string.lower(k) == "retry-after" then
			return tonumber(v)
		end
	end
	return nil
end

local function requestOnceAsync(url: string): (any?, string?, number?, { [string]: string }?)
	local ok, response = pcall(function()
		return HttpService:RequestAsync({
			Url = url,
			Method = "GET",
			Headers = {
				["X-Real-User-Agent"] = userAgent(),
				["Wally-Version"] = "0.3.2",
			},
		})
	end)
	if not ok then
		return nil, tostring(response), nil, nil
	end
	return response.Body, nil, response.StatusCode, response.Headers
end

local function fetchAsync(url: string): (string?, string?)
	RateLimiter.acquireSlotAsync()
	local body, errorMessage, statusCode, headers = requestOnceAsync(url)

	if statusCode == 429 then
		RateLimiter.backoffAsync(parseRetryAfter(headers))
		body, errorMessage, statusCode, headers = requestOnceAsync(url)
	end

	if errorMessage ~= nil then
		return nil, errorMessage
	end
	if statusCode ~= nil and (statusCode < 200 or statusCode >= 300) then
		return nil, `HTTP {statusCode}`
	end
	if body == nil then
		return nil, "Empty response"
	end

	return body, nil
end

local function cachedGetAsync(url: string): (any?, string?)
	local entry = cache[url]
	if entry ~= nil and (os.clock() - entry.time) < CACHE_TTL then
		return entry.data, nil
	end
	local body, errorMessage = fetchAsync(url)
	if body == nil then
		return nil, errorMessage
	end
	local decodeOk, data = pcall(function()
		return HttpService:JSONDecode(body)
	end)
	if not decodeOk then
		return nil, "Failed to parse response"
	end
	cache[url] = { data = data, time = os.clock() }
	return data, nil
end

local WallyAPI = {}

WallyAPI.subscribe = StatusPublisher.subscribe
WallyAPI.getStatus = StatusPublisher.get

function WallyAPI.formatWaitMessage(s: Status): string?
	if s.state ~= "waiting" then
		return nil
	end
	local remaining = math.max(0, math.ceil(s.untilClock - os.clock()))
	if s.reason == "rate-limited" then
		return `Rate limited by Wally, retrying in {remaining}s...`
	end
	return `Waiting {remaining}s to respect Wally's rate limit...`
end

function WallyAPI.searchAsync(query: string): (any?, string?)
	local trimmed = (query:gsub("^%s+", ""):gsub("%s+$", ""))
	local encoded = (HttpService:UrlEncode(trimmed):gsub("%%20", "+"))
	return cachedGetAsync(`{WALLY_API}/v1/package-search?query={encoded}`)
end

function WallyAPI.metadataAsync(scope: string, name: string): (any?, string?)
	return cachedGetAsync(`{WALLY_API}/v1/package-metadata/{scope}/{name}`)
end

function WallyAPI.downloadAsync(scope: string, name: string, version: string): (string?, string?)
	local url = `{WALLY_API}/v1/package-contents/{scope}/{name}/{version}`
	local body, errorMessage = fetchAsync(url)
	if body == nil then
		return nil, `{errorMessage} ({url})`
	end
	return body, nil
end

return WallyAPI
