--!strict

--[[
	What only pesde understands: its targets, the kinds of dependency it lists, and
		its resolved dependency graph.
]]

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const coreTypes = require(StudioDiscover.Libraries.Core.types)

-- pesde publishes a package per target. `roblox_server` is the server realm.
export type Target = "roblox" | "roblox_server"

-- A dependency on a pesde package, or on a wally package pesde proxies. Discover installs only the first.
export type Kind = "pesde" | "wally"

-- `libPath` stays writable because apply fills it in from the archive when the metadata did not have it.
export type PesdeResolvedPackage = {
	read packageId: string,
	read scope: string,
	read name: string,
	read version: string,
	read realm: coreTypes.Realm,
	libPath: string?,
	read dependencies: { coreTypes.Dependency },
}

return nil
