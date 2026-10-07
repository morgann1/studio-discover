--!strict

--[[
	The vocabulary every registry and the plugin share.

	Anything only one registry understands belongs in that registry's own types
		module, and anything that is only UI state belongs in the plugin.
]]

export type Realm = "shared" | "server"

export type Registry = "wally" | "pesde" | "nevermore"

export type ProgressCallback = (message: string) -> ()

-- One package the user asked for directly, as opposed to one pulled in as a dependency.
export type RootRequest = {
	read scope: string,
	read name: string,
	read version: string,
	read requestRealm: Realm,
	read alias: string,
}

-- A root as it currently exists in the place, read back out of its link module.
export type InstalledRoot = {
	read scope: string,
	read name: string,
	read version: string,
	read realm: Realm,
	read alias: string,
	read registry: Registry,
}

--[[
	One edge in a resolved graph: the name a package requires its dependency by,
		and the id of the package that name points at.
]]
export type Dependency = {
	read alias: string,
	read packageId: string,
}

-- A search hit, before the full metadata for a package has been fetched.
export type PackageBrief = {
	read registries: { Registry },
	read scope: string,
	read name: string,
	read description: string?,
	read latestVersion: string?,
}

-- Alias to "scope/name@constraint", as a manifest writes it.
export type DependencyMap = { [string]: string }

--[[
	The metadata the package screen renders.

	This is a view model, not any registry's wire format. Wally's API happens to
		return it almost verbatim; pesde's and npm's normalize into it. Every registry
		produces it so that the screen has one shape to render, and none has to know
		the others exist.
]]
export type PackageInfo = {
	read authors: { string },
	read description: string?,
	read license: string?,
	read realm: string,
	read version: string,
}

export type PackageVersion = {
	read package: PackageInfo,
	read dependencies: DependencyMap,
	read ["server-dependencies"]: DependencyMap,
	read ["dev-dependencies"]: DependencyMap,
}

export type PackageMetadata = {
	read versions: { PackageVersion },
}

return nil
