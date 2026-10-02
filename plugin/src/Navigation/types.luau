--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const coreTypes = require(StudioDiscover.Libraries.Core.types)

-- The package a package screen shows. `version` preselects a version when it exists.
export type PackageTarget = {
	read registry: coreTypes.Registry,
	read scope: string,
	read name: string,
	read version: string?,
}

-- Every screen that takes no arguments.
export type ScreenName = "Installed" | "Updates" | "Search" | "Settings" | "DisplayNames"

export type Route =
	{
		read name: ScreenName,
	}
	| {
		read name: "Source",
		read registry: coreTypes.Registry,
	}
	| {
		read name: "Package",
		read target: PackageTarget,
	}

-- One entry in the navigation stack. `id` is unique per push, so the same route pushed twice mounts twice.
export type Screen = {
	read id: string,
	read route: Route,
}

--[[
	The screens to go back through, ending with the one shown, and the screens going
		back left behind, ending with the one going forward returns to. `stack` is
		never empty.
]]
export type History = {
	read stack: { Screen },
	read forward: { Screen },
}

return nil
