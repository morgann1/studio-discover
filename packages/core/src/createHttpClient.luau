--!strict

const HttpService = game:GetService("HttpService")

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const buildUserAgent = require(StudioDiscover.Libraries.Core.buildUserAgent)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const createRateLimiter = require(StudioDiscover.Libraries.Core.createRateLimiter)
const describeHttpFailure = require(StudioDiscover.Libraries.Core.describeHttpFailure)

const MIN_REQUEST_INTERVAL_SECONDS = 1

export type HttpClient = {
	read getAsync: (path: string, headers: { [string]: string }?) -> (string?, string?, boolean),
	read getJsonAsync: (path: string) -> (unknown, string?, boolean),
}

-- Whether an answer outside 2xx means the requested thing doesn't exist.
export type IsMissing = (statusCode: number, body: string?) -> boolean

type Response = {
	read statusCode: number,
	read headers: { [string]: string },
	read body: string?,
}

const function findRetryAfter(headers: { [string]: string }): number?
	for key, value in headers do
		if string.lower(key) == "retry-after" then
			return tonumber(value)
		end
	end

	return nil
end

const function isNotFound(statusCode: number, _body: string?): boolean
	return statusCode == 404
end

--[[
	Returns a client for one registry's API at `baseUrl`, named `name` in the logs.

	`getAsync` returns the body of a successful GET to `path`, or nil and why not, and
		`getJsonAsync` decodes that body as JSON. The reason reads as a phrase for
		people, from `describeHttpFailure`. The third value is true when the registry
		said the thing asked for doesn't exist, which `isMissing` decides and which
		defaults to a 404.

	Requests wait their turn behind a one-second rate limit, carry Discover's user
		agent alongside `headers`, and retry once after a 429, honoring `Retry-After`.
]]
const function createHttpClient(
	name: string,
	baseUrl: string,
	headers: { [string]: string },
	isMissing: IsMissing?
): HttpClient
	const logger = createLogger.createLogger(`{name}.http`)
	const rateLimiter = createRateLimiter(MIN_REQUEST_INTERVAL_SECONDS)
	const host = string.match(baseUrl, "^%a+://([^/]+)") or baseUrl
	const checkMissing: IsMissing = isMissing or isNotFound

	const function requestOnceAsync(url: string, requestHeaders: { [string]: string | Secret }): (Response?, string?)
		const ok, response = pcall(function()
			return HttpService:RequestAsync({
				Url = url,
				Method = "GET",
				Headers = requestHeaders,
			})
		end)

		if not ok then
			return nil, tostring(response)
		end

		const result: Response = {
			statusCode = response.StatusCode,
			headers = response.Headers,
			body = response.Body,
		}

		return result, nil
	end

	const function getAsync(path: string, extraHeaders: { [string]: string }?): (string?, string?, boolean)
		const url = `{baseUrl}{path}`

		const requestHeaders: { [string]: string | Secret } = { ["X-Real-User-Agent"] = buildUserAgent() }
		for key, value in headers do
			requestHeaders[key] = value
		end
		if extraHeaders ~= nil then
			for key, value in extraHeaders do
				requestHeaders[key] = value
			end
		end

		rateLimiter.acquireAsync()
		local response, err = requestOnceAsync(url, requestHeaders)

		if response ~= nil and response.statusCode == 429 then
			task.wait(findRetryAfter(response.headers) or 1)
			rateLimiter.acquireAsync()
			response, err = requestOnceAsync(url, requestHeaders)
		end

		if response == nil then
			logger.warn(`GET {url} failed: {err}`)
			return nil, describeHttpFailure(host, { kind = "request", message = err or "" }), false
		end

		const statusCode = response.statusCode
		if statusCode < 200 or statusCode >= 300 then
			logger.warn(`GET {url} returned HTTP {statusCode}`)

			if checkMissing(statusCode, response.body) then
				return nil, describeHttpFailure(host, { kind = "missing" }), true
			end

			return nil, describeHttpFailure(host, { kind = "status", statusCode = statusCode }), false
		elseif response.body == nil or response.body == "" then
			return nil, describeHttpFailure(host, { kind = "empty" }), false
		end

		return response.body, nil, false
	end

	-- Like `getAsync`, with the body decoded as JSON. The result is unchecked, so callers narrow it.
	const function getJsonAsync(path: string): (unknown, string?, boolean)
		const body, err, missing = getAsync(path)
		if body == nil then
			return nil, err, missing
		end

		const ok, decoded = pcall(HttpService.JSONDecode, HttpService, body)
		if not ok then
			logger.warn(`GET {baseUrl}{path} sent JSON that failed to decode: {decoded}`)
			return nil, describeHttpFailure(host, { kind = "unreadable" }), false
		end

		return decoded, nil, false
	end

	return table.freeze({
		getAsync = getAsync,
		getJsonAsync = getJsonAsync,
	})
end

return createHttpClient
