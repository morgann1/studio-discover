--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const types = require(StudioDiscover.Libraries.Core.types)

const PackageGrid = require(script.Parent.PackageGrid)

const Text = Foundation.Text
const View = Foundation.View

const e = React.createElement

const FEATURED: { types.PackageBrief } = {
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
		scope = "osyrisrblx",
		name = "t",
		description = "A Runtime Typechecker for Roblox",
		latestVersion = "3.1.1",
	},
	{
		registries = { "wally" },
		scope = "sleitnick",
		name = "knit",
		description = "Knit is a lightweight game framework",
		latestVersion = "1.7.0",
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

-- A fixed list of popular Wally packages, shown on Home when Wally is enabled.
const function Featured(props: {
	read LayoutOrder: number?,
})
	const nextOrder = createNextOrder()

	return e(View, {
		tag = "size-full-0 auto-y col gap-medium",
		LayoutOrder = props.LayoutOrder,
	}, {
		Heading = e(Text, {
			tag = "size-full-0 auto-y text-title-large content-emphasis text-align-x-left",
			Text = "Featured",
			LayoutOrder = nextOrder(),
		}),
		Cards = e(PackageGrid, {
			packages = FEATURED,
			LayoutOrder = nextOrder(),
		}),
	})
end

return Featured
