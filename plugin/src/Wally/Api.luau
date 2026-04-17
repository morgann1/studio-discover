local Discover = script:FindFirstAncestor("Discover")

local HttpService = game:GetService("HttpService")
local StudioService = game:GetService("StudioService")

local Version = require(Discover.Src.Version)

local DEFAULT_BACKEND_URL = "https://wally.morgann1.com"

local CACHE_TTL = 300
local MIN_INTERVAL = 1.05

local backendUrl = DEFAULT_BACKEND_URL

export type Status = {
	state: "idle" | "waiting",
	reason: "queue" | "rate-limited" | nil,
	untilClock: number,
}

local WallyAPI = {}

local cache: { [string]: { data: any, time: number } } = {}

local nextSlotClock = 0

local status: Status = { state = "idle", reason = nil, untilClock = 0 }
local subscribers: { (Status) -> () } = {}

local function notify()
	for _, cb in subscribers do
		task.spawn(cb, status)
	end
end

local function setStatus(state: "idle" | "waiting", reason: "queue" | "rate-limited" | nil, untilClock: number)
	status = { state = state, reason = reason, untilClock = untilClock }
	notify()
end

function WallyAPI.subscribe(callback: (Status) -> ()): () -> ()
	table.insert(subscribers, callback)
	task.spawn(callback, status)
	return function()
		for i, cb in subscribers do
			if cb == callback then
				table.remove(subscribers, i)
				break
			end
		end
	end
end

function WallyAPI.getStatus(): Status
	return status
end

function WallyAPI.setBackendUrl(url: string)
	local trimmed = url:gsub("/+$", "")
	backendUrl = if trimmed == "" then DEFAULT_BACKEND_URL else trimmed
end

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

local function acquireSlot()
	local now = os.clock()
	local mySlot = if nextSlotClock > now then nextSlotClock else now
	nextSlotClock = mySlot + MIN_INTERVAL
	local wait = mySlot - now
	if wait > 0 then
		setStatus("waiting", "queue", mySlot)
		task.wait(wait)
		if status.untilClock <= os.clock() then
			setStatus("idle", nil, 0)
		end
	end
end

local function parseRetryAfter(headers: { [string]: string }?): number
	if not headers then
		return MIN_INTERVAL
	end
	for k, v in headers do
		if string.lower(k) == "retry-after" then
			local seconds = tonumber(v)
			if seconds then
				return seconds
			end
		end
	end
	return MIN_INTERVAL
end

local function waitRateLimited(seconds: number)
	local untilClock = os.clock() + seconds
	if untilClock > nextSlotClock then
		nextSlotClock = untilClock
	end
	setStatus("waiting", "rate-limited", untilClock)
	task.wait(seconds)
	if status.untilClock <= os.clock() then
		setStatus("idle", nil, 0)
	end
end

local function requestOnce(url: string): (any?, string?, number?, { [string]: string }?)
	local ok, response = pcall(function()
		return HttpService:RequestAsync({
			Url = url,
			Method = "GET",
			Headers = {
				["X-Studio-UserId"] = tostring(StudioService:GetUserId()),
				["X-Plugin-Version"] = Version,
			},
		})
	end)
	if not ok then
		return nil, tostring(response), nil, nil
	end
	return response.Body, nil, response.StatusCode, response.Headers
end

local function wallyFetch(url: string): (string?, string?)
	acquireSlot()
	local body, errorMessage, statusCode, headers = requestOnce(url)

	if statusCode == 429 then
		local retry = parseRetryAfter(headers)
		waitRateLimited(retry)
		body, errorMessage, statusCode, headers = requestOnce(url)
	end

	if errorMessage then
		return nil, errorMessage
	end
	if statusCode and (statusCode < 200 or statusCode >= 300) then
		return nil, `HTTP {statusCode}`
	end
	if not body then
		return nil, "Empty response"
	end

	return body, nil
end

local function wallyGet(url: string)
	local body, errorMessage = wallyFetch(url)
	if not body then
		return nil, errorMessage
	end

	local decodeOk, data = pcall(function()
		return HttpService:JSONDecode(body)
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
	local data, errorMessage = wallyGet(url)
	if data then
		cache[url] = { data = data, time = os.clock() }
	end
	return data, errorMessage
end

function WallyAPI.search(query: string)
	local trimmed = (query:gsub("^%s+", ""):gsub("%s+$", ""))
	local encoded = (HttpService:UrlEncode(trimmed):gsub("%%20", "+"))
	return cachedGet(`{backendUrl}/v1/package-search?query={encoded}`)
end

function WallyAPI.metadata(scope: string, name: string)
	return cachedGet(`{backendUrl}/v1/package-metadata/{scope}/{name}`)
end

function WallyAPI.download(scope: string, name: string, version: string): (string?, string?)
	local url = `{backendUrl}/v1/package-contents/{scope}/{name}/{version}`
	local body, errorMessage = wallyFetch(url)
	if not body then
		return nil, `{errorMessage} ({url})`
	end
	return body, nil
end

return WallyAPI
