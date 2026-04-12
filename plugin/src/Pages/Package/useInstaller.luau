local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)

local InstalledState = require(Discover.Src.Installer.InstalledStore)
local Installer = require(Discover.Src.Installer.Installer)

type InstallerState = {
	status: string,
	error: string?,
	progress: string?,
	run: () -> (),
}

local function useInstaller(
	scope: string,
	name: string,
	version: string,
	alias: string,
	realm: string,
	verboseLogging: boolean,
	selectedVersion: string?
): InstallerState
	local status, setStatus = React.useState("idle")
	local installError: string?, setError = React.useState(nil :: string?)
	local progress: string?, setProgress = React.useState(nil :: string?)

	React.useEffect(function()
		setStatus("idle")
		setError(nil)
		return nil
	end, { selectedVersion })

	local run = React.useCallback(function()
		setStatus("installing")
		setError(nil)
		setProgress("Starting install...")

		task.spawn(function()
			Installer.setVerbose(verboseLogging)
			local success, errorMessage, failures = Installer.install(
				scope,
				name,
				version,
				alias,
				realm,
				function(message)
					setProgress(message)
				end
			)
			setProgress(nil)

			if success then
				InstalledState.refresh()
				if failures and #failures > 0 then
					setStatus("partial")
					setError(
						`Installed, but {#failures} {if #failures == 1 then "dependency" else "dependencies"} failed:\n• `
							.. table.concat(failures, "\n• ")
					)
				else
					setStatus("installed")
					setError(nil)
				end
			else
				setStatus("error")
				setError(errorMessage)
				warn("[Discover] Install failed:", errorMessage)
			end
		end)
	end, { scope, name, version, alias, realm, verboseLogging } :: { any })

	return {
		status = status,
		error = installError,
		progress = progress,
		run = run,
	}
end

return useInstaller
