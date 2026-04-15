local HttpService = game:GetService("HttpService")

local API_BASE = "https://api.wally.run/v1"
local PLUGIN_VERSION = "2.5.0"
local CLIENT_ID = `studio-discover/{PLUGIN_VERSION} (https://github.com/morgann1/studio-discover)`
local MIN_REQUEST_INTERVAL = 1

local nextAllowedRequestAt = 0

export type PackageVersion = {
	package: {
		name: string,
		version: string,
		registry: string,
		realm: string?,
		description: string?,
		license: string?,
		authors: { string }?,
	},
	dependencies: { [string]: string }?,
	["server-dependencies"]: { [string]: string }?,
	["dev-dependencies"]: { [string]: string }?,
}

export type PackageMetadata = {
	versions: { PackageVersion },
}

export type SearchResult = {
	scope: string,
	name: string,
	description: string?,
	versions: { string },
}

export type ApiResult<T> =
	{
		ok: true,
		data: T,
	}
	| {
		ok: false,
		error: string,
	}

local responseCache: { [string]: ApiResult<any> } = {}
local inFlight: { [string]: BindableEvent } = {}

local function fetch(url: string): ApiResult<any>
	local now = os.clock()
	if now < nextAllowedRequestAt then
		task.wait(nextAllowedRequestAt - now)
	end
	nextAllowedRequestAt = os.clock() + MIN_REQUEST_INTERVAL

	local requestOk, response = pcall(function()
		return HttpService:RequestAsync({
			Url = url,
			Method = "GET",
			Headers = {
				Accept = "application/json",
				["Wally-Version"] = PLUGIN_VERSION,
				["X-Client"] = CLIENT_ID,
			},
		})
	end)

	if not requestOk then
		return { ok = false, error = tostring(response) }
	end
	if not response.Success then
		return { ok = false, error = `HTTP {response.StatusCode}: {response.StatusMessage}` }
	end

	local decodeOk, decoded = pcall(HttpService.JSONDecode, HttpService, response.Body)
	if not decodeOk then
		return { ok = false, error = `JSON decode failed: {tostring(decoded)}` }
	end

	return { ok = true, data = decoded }
end

local function get(url: string): ApiResult<any>
	local cached = responseCache[url]
	if cached then
		return cached
	end

	local pending = inFlight[url]
	if pending then
		pending.Event:Wait()
		return responseCache[url] or { ok = false, error = "in-flight request finished without a result" }
	end

	local signal = Instance.new("BindableEvent")
	inFlight[url] = signal

	local result = fetch(url)
	if result.ok then
		responseCache[url] = result
	end

	inFlight[url] = nil
	signal:Fire()
	signal:Destroy()

	return result
end

local function getPackageMetadata(scope: string, name: string): ApiResult<PackageMetadata>
	return get(`{API_BASE}/package-metadata/{scope}/{name}`)
end

-- application/x-www-form-urlencoded encoding to match wally.run's
-- frontend (URLSearchParams) — spaces become "+", everything outside
-- the unreserved set becomes %XX.
local function encodeFormParam(value: string): string
	return (
		string.gsub(value, "([^%w%-%.%_%~])", function(char)
			if char == " " then
				return "+"
			end
			return string.format("%%%02X", string.byte(char))
		end)
	)
end

local function searchPackages(query: string): ApiResult<{ SearchResult }>
	return get(`{API_BASE}/package-search?query={encodeFormParam(query)}`)
end

local function clearCache()
	table.clear(responseCache)
end

return {
	getPackageMetadata = getPackageMetadata,
	searchPackages = searchPackages,
	clearCache = clearCache,
}
