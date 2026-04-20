--!strict

export type Registry = "wally" | "pesde"

export type PackageBrief = {
	registry: Registry,
	scope: string,
	name: string,
	description: string?,
	latestVersion: string?,
}

export type WallyPackageBrief = {
	scope: string,
	name: string,
	description: string?,
	versions: { string },
}

export type WallyDependencyMap = { [string]: string }

export type WallyPackageInfo = {
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

export type WallyPackageVersion = {
	package: WallyPackageInfo,
	place: {
		["shared-packages"]: string?,
		["server-packages"]: string?,
	},
	dependencies: WallyDependencyMap,
	["server-dependencies"]: WallyDependencyMap,
	["dev-dependencies"]: WallyDependencyMap,
}

export type WallyPackageMetadata = {
	versions: { WallyPackageVersion },
}

return nil
