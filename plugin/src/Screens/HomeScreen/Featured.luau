--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

local PackageCard = require(script.Parent.PackageCard)

local Text = Foundation.Text
local View = Foundation.View

local e = React.createElement

type Entry = {
	scope: string,
	name: string,
	description: string?,
	latestVersion: string?,
}

local FEATURED: { Entry } = table.freeze({
	{
		scope = "jsdotlua",
		name = "react",
		latestVersion = "17.2.1",
	} :: Entry,
	{
		scope = "sleitnick",
		name = "signal",
		description = "Signal class",
		latestVersion = "2.0.3",
	},
	{
		scope = "evaera",
		name = "promise",
		description = "Promise implementation for Roblox",
		latestVersion = "4.0.0",
	},
	{
		scope = "osyrisrblx",
		name = "t",
		description = "A Runtime Typechecker for Roblox",
		latestVersion = "3.1.1",
	},
	{
		scope = "sleitnick",
		name = "knit",
		description = "Knit is a lightweight game framework",
		latestVersion = "1.7.0",
	},
	{
		scope = "howmanysmall",
		name = "janitor",
		description = "A garbage collector object implementation for Roblox, featuring support for custom cleanup methods, Promises, and instance linking.",
		latestVersion = "1.18.3",
	},
	{
		scope = "sleitnick",
		name = "trove",
		description = "Trove class for tracking and cleaning up objects",
		latestVersion = "1.8.0",
	},
	{
		scope = "littensy",
		name = "charm",
		latestVersion = "0.11.0-rc.5",
	} :: Entry,
}) :: { Entry }

type Props = {
	LayoutOrder: number?,
}

local function Featured(props: Props)
	local nextOrder = createNextOrder()

	local children: { [string]: any } = {}
	children.Heading = e(Text, {
		tag = "size-full-0 auto-y text-title-large content-emphasis text-align-x-left",
		Text = "Featured",
		LayoutOrder = nextOrder(),
	})

	for _, pkg in FEATURED do
		children[`{pkg.scope}/{pkg.name}`] = e(PackageCard, {
			registry = "wally",
			scope = pkg.scope,
			name = pkg.name,
			description = pkg.description,
			latestVersion = pkg.latestVersion,
			LayoutOrder = nextOrder(),
		})
	end

	return e(View, {
		tag = "size-full-0 auto-y col gap-medium",
		LayoutOrder = props.LayoutOrder,
	}, children)
end

return Featured
