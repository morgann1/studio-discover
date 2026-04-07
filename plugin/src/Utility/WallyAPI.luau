--[[
	Wally API client.

	Per https://wally.run/policies the registry requires no more than
	1 request per second. This module enforces that via a shared serial
	queue: callers still get normal return values, but internally only
	one request is in flight at a time and each request waits at least
	MIN_INTERVAL seconds after the previous one started.
]]

local HttpService = game:GetService("HttpService")

local WALLY_SEARCH_API = "https://api.wally.run/v1/package-search?query="
local WALLY_METADATA_API = "https://api.wally.run/v1/package-metadata/"

local CACHE_TTL = 300
local MIN_INTERVAL = 1.05 -- seconds between requests (small buffer over 1/sec)

local WallyAPI = {}

local cache: { [string]: { data: any, time: number } } = {}

-- Next clock time at which a new request may be sent. Each caller
-- atomically reserves a slot and waits. Because Luau coroutines don't
-- preempt, the reservation (before any yield) is effectively atomic.
local nextSlotClock = 0

local function acquireSlot()
	local now = os.clock()
	local mySlot = if nextSlotClock > now then nextSlotClock else now
	nextSlotClock = mySlot + MIN_INTERVAL
	local wait = mySlot - now
	if wait > 0 then
		task.wait(wait)
	end
end

local function wallyGet(url: string)
	acquireSlot()
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
