--!strict

export type WallyPackageBrief = {
	scope: string,
	name: string,
	description: string,
	versions: { string },
}

export type WallyDependencyMap = { [string]: string }

export type WallyPackageInfo = {
	authors: { string },
	description: string,
	license: string,
	name: string,
	realm: string,
	registry: string,
	version: string,
	homepage: string?,
	repository: string?,
}

export type WallyPackageMetadata = {
	package: WallyPackageInfo,
	place: {
		["shared-packages"]: string?,
		["server-packages"]: string?,
	},
	dependencies: WallyDependencyMap,
	["server-dependencies"]: WallyDependencyMap,
	["dev-dependencies"]: WallyDependencyMap,
}

return nil
