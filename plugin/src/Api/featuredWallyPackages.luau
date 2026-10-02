--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const types = require(StudioDiscover.Libraries.Core.types)

--[[
	Popular Wally packages, which the Wally source lists before the user searches.
		Wally has no listing of its own to show instead.
]]
const featuredWallyPackages: { types.PackageBrief } = {
	{
		registries = { "wally" },
		scope = "sleitnick",
		name = "knit",
		description = "Knit is a lightweight game framework",
		latestVersion = "1.7.0",
	},
	{
		registries = { "wally" },
		scope = "roblox",
		name = "react",
		latestVersion = "17.3.12",
	},
	{
		registries = { "wally" },
		scope = "sleitnick",
		name = "signal",
		description = "Signal class",
		latestVersion = "2.0.3",
	},
	{
		registries = { "wally" },
		scope = "evaera",
		name = "promise",
		description = "Promise implementation for Roblox",
		latestVersion = "4.0.0",
	},
	{
		registries = { "wally" },
		scope = "howmanysmall",
		name = "janitor",
		description = "A garbage collector object implementation for Roblox, featuring support for custom cleanup methods, Promises, and instance linking.",
		latestVersion = "1.18.3",
	},
	{
		registries = { "wally" },
		scope = "osyrisrblx",
		name = "t",
		description = "A Runtime Typechecker for Roblox",
		latestVersion = "3.1.1",
	},
	{
		registries = { "wally" },
		scope = "sleitnick",
		name = "trove",
		description = "Trove class for tracking and cleaning up objects",
		latestVersion = "1.8.0",
	},
	{
		registries = { "wally" },
		scope = "littensy",
		name = "charm",
		latestVersion = "0.11.0-rc.5",
	},
}
table.freeze(featuredWallyPackages)

return featuredWallyPackages
