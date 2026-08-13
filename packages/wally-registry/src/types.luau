--!strict

--[[
	What only Wally understands: its resolved dependency graph, and the shape its
	search endpoint returns.

	The metadata the package screen renders is registry-neutral and lives in
	`Core.types` as `PackageMetadata`, because pesde normalizes into it too.
]]

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local coreTypes = require(StudioDiscover.Core.types)

type Realm = coreTypes.Realm

-- One edge in the resolved graph: the name a package requires its dependency by,
-- and the `_Index` entry that name points at.
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

export type WallyPackageBrief = {
	scope: string,
	name: string,
	description: string?,
	versions: { string },
}

return nil
