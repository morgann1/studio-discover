--!strict

--[[
	What only Nevermore understands: its resolved graph, keyed by npm package id,
		and how that graph lays out in `node_modules`.
]]

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const coreTypes = require(StudioDiscover.Libraries.Core.types)

--[[
	One package version in the graph. `name` is the npm name, such as "@quenty/maid",
		and each edge's alias is the npm name of the dependency it points at.
]]
export type NevermoreResolvedPackage = {
	read packageId: string,
	read name: string,
	read version: string,
	read dependencies: { coreTypes.Dependency },
}

--[[
	One copy of a package in `node_modules`, and the copies nested in its own
		`node_modules`, keyed by npm name. A package sits in more than one place when
		two packages need different versions of it, as npm installs it.
]]
export type Placement = {
	read packageId: string,
	read name: string,
	read children: { [string]: Placement },
}

return nil
