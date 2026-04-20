--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local CompactContext = require(StudioDiscover.Source.Common.CompactContext)
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

local function renderCard(pkg: Entry): any
	return e(PackageCard, {
		registries = { "wally" },
		scope = pkg.scope,
		name = pkg.name,
		description = pkg.description,
		latestVersion = pkg.latestVersion,
	})
end

local function Featured(props: Props)
	local compact = CompactContext.useCompact()

	local cards: { [string]: any } = {}
	if compact then
		local cardOrder = createNextOrder()
		for _, pkg in FEATURED do
			cards[`{pkg.scope}/{pkg.name}`] = e(PackageCard, {
				registries = { "wally" },
				scope = pkg.scope,
				name = pkg.name,
				description = pkg.description,
				latestVersion = pkg.latestVersion,
				LayoutOrder = cardOrder(),
			})
		end
	else
		local rowOrder = createNextOrder()
		for i = 1, #FEATURED, 2 do
			local pkgA = FEATURED[i]
			local pkgB = FEATURED[i + 1]
			local cells: { [string]: any } = {
				Left = e(View, {
					tag = "grow auto-y",
					LayoutOrder = 1,
				}, {
					Card = renderCard(pkgA),
				}),
				Right = e(View, {
					tag = "grow auto-y",
					LayoutOrder = 2,
				}, if pkgB ~= nil then { Card = renderCard(pkgB) } else nil),
			}
			cards[`row_{i}`] = e(View, {
				tag = "size-full-0 auto-y row align-y-top gap-medium",
				LayoutOrder = rowOrder(),
			}, cells)
		end
	end

	return e(View, {
		tag = "size-full-0 auto-y col gap-medium",
		LayoutOrder = props.LayoutOrder,
	}, {
		Heading = e(Text, {
			tag = "size-full-0 auto-y text-title-large content-emphasis text-align-x-left",
			Text = "Featured",
			LayoutOrder = 1,
		}),
		Cards = e(View, {
			tag = "size-full-0 auto-y col gap-medium",
			LayoutOrder = 2,
		}, cards),
	})
end

return Featured
