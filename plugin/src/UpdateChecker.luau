local HttpService = game:GetService("HttpService")

local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)

local Version = require(Discover.Src.Version)
local isNewerSemver = require(Discover.Src.Util.isNewerSemver)
local useCancellableEffect = require(Discover.Src.Common.useCancellableEffect)

local RELEASES_API = "https://api.github.com/repos/morgann1/studio-discover/releases/latest"
local CHECK_INTERVAL = 3600

type UpdateInfo = {
	version: string,
	url: string,
}

local function fetchLatestRelease(): UpdateInfo?
	local ok, result = pcall(function()
		return HttpService:RequestAsync({
			Url = RELEASES_API,
			Method = "GET",
		})
	end)
	if not ok or not result.Success then
		return nil
	end

	local decoded = HttpService:JSONDecode(result.Body)
	if not decoded or not decoded.tag_name then
		return nil
	end

	local version = decoded.tag_name:gsub("^v", "")
	local url = decoded.html_url or "https://github.com/morgann1/studio-discover/releases/latest"

	if isNewerSemver(version, Version) then
		return { version = version, url = url }
	end
	return nil
end

local function useUpdateChecker(isEnabled: boolean, widgetEnabled: boolean): UpdateInfo?
	local update: UpdateInfo?, setUpdate = React.useState(nil :: UpdateInfo?)
	local lastCheckTime, setLastCheckTime = React.useState(0)

	useCancellableEffect(function(isCancelled)
		if not isEnabled or not widgetEnabled then
			return
		end

		if os.clock() - lastCheckTime < CHECK_INTERVAL then
			return
		end

		task.spawn(function()
			local info = fetchLatestRelease()
			if isCancelled() then
				return
			end
			setUpdate(info)
			setLastCheckTime(os.clock())
		end)
	end, { isEnabled, widgetEnabled } :: { any })

	React.useEffect(function()
		if not isEnabled then
			setUpdate(nil)
		end
		return nil
	end, { isEnabled })

	return update
end

return {
	useUpdateChecker = useUpdateChecker,
	currentVersion = Version,
}
