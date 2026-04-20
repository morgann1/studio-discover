--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local types = require(StudioDiscover.Source.Installer.types)

export type Realm = types.Realm
export type ProgressCallback = types.ProgressCallback

export type Kind = "pesde" | "wally"

export type PesdeDependency = {
	alias: string,
	packageId: string,
}

export type PesdeResolvedPackage = {
	packageId: string,
	scope: string,
	name: string,
	version: string,
	realm: Realm,
	kind: Kind,
	libPath: string?,
	dependencies: { PesdeDependency },
}

return nil
