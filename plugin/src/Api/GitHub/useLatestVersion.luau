--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local React = require(StudioDiscover.Packages.React)

local SettingsStore = require(StudioDiscover.Source.SettingsStore)
local getLatestReleaseAsync = require(StudioDiscover.Source.Api.GitHub.getLatestReleaseAsync)

export type LatestVersionState = {
	loading: boolean,
	version: string?,
	error: string?,
}

local EMPTY: LatestVersionState = { loading = false, version = nil, error = nil }

-- Disabled when the Check for Updates setting is off; otherwise fetches the
-- latest release tag once per plugin session.
local function useLatestVersion(): LatestVersionState
	local settings = SettingsStore.useSettings()
	local enabled = settings.checkForUpdates
	local state: LatestVersionState, setState = React.useState(EMPTY)

	React.useEffect(function(): (() -> ())?
		if not enabled then
			setState(EMPTY)
			return nil
		end

		local cancelled = false
		setState({ loading = true, version = nil, error = nil })

		task.spawn(function()
			local version, err = getLatestReleaseAsync()
			if cancelled then
				return
			end
			setState({ loading = false, version = version, error = err })
		end)

		return function()
			cancelled = true
		end
	end, { enabled })

	return state
end

return useLatestVersion
