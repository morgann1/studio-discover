--!strict

--[[
	Installer UI state, read by the package screen through `installerAtom`, and what
		the installer operations take and return.

	The shared vocabulary lives in `Core.types`, and each registry's resolved graph
		lives in that registry's own types module.
]]

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const coreTypes = require(StudioDiscover.Libraries.Core.types)

export type InstallStatus = "idle" | "running" | "success" | "error"

export type InstallerTarget = {
	read scope: string,
	read name: string,
	read version: string,
}

export type InstallerState = {
	read status: InstallStatus,
	read message: string?,
	read errors: { string },
	read target: InstallerTarget?,
}

-- One package version the user asked to install.
export type InstallRequest = {
	read registry: coreTypes.Registry,
	read scope: string,
	read name: string,
	read version: string,
	read realm: coreTypes.Realm,
}

-- An installed root with a newer version on its registry.
export type UpdateInfo = {
	read registry: coreTypes.Registry,
	read scope: string,
	read name: string,
	read realm: coreTypes.Realm,
	read alias: string,
	read installedVersion: string,
	read latestVersion: string,
}

-- `failures` holds the non-fatal warnings on success, and everything that went wrong on failure.
export type OperationResult =
	{
		read ok: true,
		read failures: { string },
	}
	| {
		read ok: false,
		read error: string,
		read failures: { string },
	}

return nil
