--!strict

--[[
	Installer UI state, read by the package screen through `installerAtom`.

	The shared vocabulary lives in `Core.types`, and each registry's resolved graph
	lives in that registry's own types module.
]]

export type InstallStatus = "idle" | "running" | "success" | "error"

export type InstallerTarget = {
	scope: string,
	name: string,
	version: string,
}

export type InstallerState = {
	status: InstallStatus,
	message: string?,
	errors: { string },
	target: InstallerTarget?,
}

return nil
