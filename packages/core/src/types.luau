--!strict

--[[
	The vocabulary both registries and the plugin share.

	Anything only one registry understands belongs in that registry's own types
	module, and anything that is only UI state belongs in the plugin.
]]

export type Realm = "shared" | "server"

export type Registry = "wally" | "pesde"

export type ProgressCallback = (message: string) -> ()

-- One package the user asked for directly, as opposed to one pulled in as a dependency.
export type RootRequest = {
	scope: string,
	name: string,
	version: string,
	requestRealm: Realm,
	alias: string,
}

-- A root as it currently exists in the place, read back out of the lockfile.
export type InstalledRoot = {
	scope: string,
	name: string,
	version: string,
	realm: Realm,
	alias: string,
	registry: Registry,
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

-- A search hit, before the full metadata for a package has been fetched.
export type PackageBrief = {
	registries: { Registry },
	scope: string,
	name: string,
	description: string?,
	latestVersion: string?,
}

--[[
	The metadata the package screen renders.

	This is a view model, not either registry's wire format. Wally's API happens to
	return it almost verbatim; pesde's normalizes into it. Both registries produce
	it so that the screen has one shape to render, and neither has to know the
	other exists.
]]

-- Alias to "scope/name@constraint", as a manifest writes it.
export type DependencyMap = { [string]: string }

export type PackageInfo = {
	authors: { string },
	description: string?,
	license: string?,
	name: string,
	realm: string,
	registry: string,
	version: string,
	homepage: string?,
	repository: string?,
}

export type PackageVersion = {
	package: PackageInfo,
	place: {
		["shared-packages"]: string?,
		["server-packages"]: string?,
	},
	dependencies: DependencyMap,
	["server-dependencies"]: DependencyMap,
	["dev-dependencies"]: DependencyMap,
}

export type PackageMetadata = {
	versions: { PackageVersion },
}

return nil
