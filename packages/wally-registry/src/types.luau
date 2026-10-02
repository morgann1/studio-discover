--!strict

--[[
	What only Wally understands: its resolved dependency graph.

	The metadata the package screen renders is registry-neutral and lives in
		`Core.types` as `PackageMetadata`, because pesde normalizes into it too.
]]

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const coreTypes = require(StudioDiscover.Libraries.Core.types)

-- `realm` stays writable because resolve promotes a server package to shared once something shared needs it.
export type ResolvedPackage = {
	read scope: string,
	read name: string,
	read version: string,
	realm: coreTypes.Realm,
	read packageId: string,
	read dependencies: { coreTypes.Dependency },
}

return nil
