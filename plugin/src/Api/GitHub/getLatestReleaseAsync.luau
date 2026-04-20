--!strict

local HttpService = game:GetService("HttpService")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local createLogger = require(StudioDiscover.Source.Util.createLogger)

local logger = createLogger.createLogger("api.latestRelease")

local URL = "https://api.github.com/repos/morgann1/studio-discover/releases/latest"

local function getLatestReleaseAsync(): (string?, string?)
	local ok, response = pcall(function()
		return HttpService:RequestAsync({
			Url = URL,
			Method = "GET",
		})
	end)
	if not ok then
		logger.warn(`release request failed: {response}`)
		return nil, tostring(response)
	end
	if response.StatusCode < 200 or response.StatusCode >= 300 then
		logger.warn(`release request HTTP {response.StatusCode}`)
		return nil, `HTTP {response.StatusCode}`
	end

	local decodeOk, decoded = pcall(function()
		return HttpService:JSONDecode(response.Body)
	end)
	if not decodeOk then
		return nil, `JSON decode failed: {decoded}`
	end

	local tag = (decoded :: any).tag_name
	if typeof(tag) ~= "string" then
		return nil, "missing tag_name"
	end

	local version = (string.gsub(tag, "^v", ""))
	logger.info(`latest release tag = {tag} (version {version})`)
	return version, nil
end

return getLatestReleaseAsync
