--!strict

local HttpService = game:GetService("HttpService")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Version = require(StudioDiscover.Source.Util.Version)

local rateLimiter = require(StudioDiscover.Source.Api.rateLimiter)

local API_BASE = "https://api.wally.run/v1"
local USER_AGENT = `StudioDiscover/{Version} (+https://github.com/morgann1/studio-discover)`
local WALLY_VERSION = "0.3.2"

type Response = {
	body: string?,
	error: string?,
	statusCode: number?,
	headers: { [string]: string }?,
}

local function parseRetryAfter(headers: { [string]: string }?): number?
	if headers == nil then
		return nil
	end
	for key, value in headers do
		if string.lower(key) == "retry-after" then
			return tonumber(value)
		end
	end
	return nil
end

local function requestOnceAsync(path: string): Response
	local success, response = pcall(function()
		return HttpService:RequestAsync({
			Url = `{API_BASE}{path}`,
			Method = "GET",
			Headers = {
				["X-Real-User-Agent"] = USER_AGENT,
				["Wally-Version"] = WALLY_VERSION,
			},
		})
	end)
	if not success then
		return { error = tostring(response) }
	end
	return {
		body = response.Body,
		statusCode = response.StatusCode,
		headers = response.Headers,
	}
end

local function requestAsync(path: string): (string?, string?)
	rateLimiter.acquireAsync()
	local response = requestOnceAsync(path)

	if response.statusCode == 429 then
		local retryAfter = parseRetryAfter(response.headers) or 1
		task.wait(retryAfter)
		response = requestOnceAsync(path)
	end

	if response.error ~= nil then
		return nil, response.error
	end
	if response.statusCode ~= nil and (response.statusCode < 200 or response.statusCode >= 300) then
		return nil, `HTTP {response.statusCode}`
	end
	if response.body == nil then
		return nil, "Empty response"
	end

	return response.body, nil
end

return table.freeze({
	requestAsync = requestAsync,
})
