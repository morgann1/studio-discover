local HttpService = game:GetService("HttpService")

local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)

local Version = require(Discover.Src.Version)

local RELEASES_API = "https://api.github.com/repos/morgann1/studio-discover/releases/latest"
local CHECK_INTERVAL = 3600

type UpdateInfo = {
	version: string,
	url: string,
}

local function parseVersion(version: string): { major: number, minor: number, patch: number }?
	local cleaned = version:gsub("^v", "")
	local major, minor, patch = cleaned:match("^(%d+)%.(%d+)%.(%d+)")
	if not major then
		return nil
	end
	return { major = tonumber(major) :: number, minor = tonumber(minor) :: number, patch = tonumber(patch) :: number }
end

local function isNewer(remote: string, current: string): boolean
	local r = parseVersion(remote)
	local c = parseVersion(current)
	if not r or not c then
		return false
	end
	if r.major ~= c.major then
		return r.major > c.major
	end
	if r.minor ~= c.minor then
		return r.minor > c.minor
	end
	return r.patch > c.patch
end

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

	if isNewer(version, Version) then
		return { version = version, url = url }
	end
	return nil
end

local function useUpdateChecker(isEnabled: boolean, widgetEnabled: boolean): UpdateInfo?
	local update: UpdateInfo?, setUpdate = React.useState(nil :: UpdateInfo?)
	local lastCheckTime, setLastCheckTime = React.useState(0)

	React.useEffect(function()
		if not isEnabled or not widgetEnabled then
			return nil
		end

		if os.clock() - lastCheckTime < CHECK_INTERVAL then
			return nil
		end

		local cancelled = false

		task.spawn(function()
			local info = fetchLatestRelease()
			if not cancelled then
				setUpdate(info)
				setLastCheckTime(os.clock())
			end
		end)

		return function()
			cancelled = true
		end
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
