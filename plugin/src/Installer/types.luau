--!strict

export type Realm = "shared" | "server"

export type Dependency = {
	alias: string,
	packageId: string,
	realm: Realm,
}

export type ResolvedPackage = {
	scope: string,
	name: string,
	version: string,
	realm: Realm,
	packageId: string,
	dependencies: { Dependency },
}

export type RootRequest = {
	scope: string,
	name: string,
	version: string,
	requestRealm: Realm,
	alias: string,
}

export type LockDependency = {
	alias: string,
	packageId: string,
}

export type LockEntry = {
	name: string,
	version: string,
	realm: Realm,
	dependencies: { LockDependency },
}

export type ProgressCallback = (message: string) -> ()

export type InstallStatus = "idle" | "running" | "success" | "error"

export type InstallerState = {
	status: InstallStatus,
	message: string?,
	errors: { string },
}

return nil
