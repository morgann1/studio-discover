--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const coreTypes = require(StudioDiscover.Libraries.Core.types)

-- The package a package screen shows. `version` preselects a version when it exists.
export type PackageTarget = {
	read registries: { coreTypes.Registry },
	read scope: string,
	read name: string,
	read version: string?,
}

-- Every screen that takes no arguments.
export type ScreenName = "Home" | "Manage" | "Updates" | "Settings" | "DisplayNames" | "Registries"

export type Route =
	{
		read name: ScreenName,
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

return nil
