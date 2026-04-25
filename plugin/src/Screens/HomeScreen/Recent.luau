--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local types = require(StudioDiscover.Source.Api.types)

local CompactContext = require(StudioDiscover.Source.Common.CompactContext)
local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

local PackageCard = require(script.Parent.PackageCard)
local useRecent = require(script.Parent.useRecent)

local Loading = Foundation.Loading
local Text = Foundation.Text
local View = Foundation.View

local e = React.createElement

type Props = {
	LayoutOrder: number?,
}

local function renderCard(pkg: types.PackageBrief): any
	return e(PackageCard, {
		registries = pkg.registries,
		scope = pkg.scope,
		name = pkg.name,
		description = pkg.description,
		latestVersion = pkg.latestVersion,
	})
end

local function Recent(props: Props)
	local state = useRecent()
	local compact = CompactContext.useCompact()

	local sectionOrder = createNextOrder()
	local headingOrder = sectionOrder()
	local bodyOrder = sectionOrder()

	local body: React.ReactNode
	if state.loading then
		body = e(View, {
			tag = "size-full-0 auto-y align-x-center padding-medium",
			LayoutOrder = bodyOrder,
		}, {
			Inner = e(Loading, {}),
		})
	elseif state.error ~= nil or #state.packages == 0 then
		body = e(Text, {
			tag = "size-full-0 auto-y text-body-medium content-muted text-align-x-left",
			Text = state.error or "No recent pesde packages available.",
			LayoutOrder = bodyOrder,
		})
	else
		local cards: { [string]: any } = {}
		if compact then
			local cardOrder = createNextOrder()
			for _, pkg in state.packages do
				cards[`{pkg.scope}/{pkg.name}`] = e(PackageCard, {
					registries = pkg.registries,
					scope = pkg.scope,
					name = pkg.name,
					description = pkg.description,
					latestVersion = pkg.latestVersion,
					LayoutOrder = cardOrder(),
				})
			end
		else
			local rowOrder = createNextOrder()
			for i = 1, #state.packages, 2 do
				local pkgA = state.packages[i]
				local pkgB = state.packages[i + 1]
				local cellOrder = createNextOrder()
				local cells: { [string]: any } = {
					Left = e(View, {
						tag = "grow auto-y",
						LayoutOrder = cellOrder(),
					}, {
						Card = renderCard(pkgA),
					}),
					Right = e(View, {
						tag = "grow auto-y",
						LayoutOrder = cellOrder(),
					}, if pkgB ~= nil then { Card = renderCard(pkgB) } else nil),
				}
				cards[`row_{i}`] = e(View, {
					tag = "size-full-0 auto-y row align-y-top gap-medium",
					LayoutOrder = rowOrder(),
				}, cells)
			end
		end
		body = e(View, {
			tag = "size-full-0 auto-y col gap-medium",
			LayoutOrder = bodyOrder,
		}, cards)
	end

	return e(View, {
		tag = "size-full-0 auto-y col gap-medium",
		LayoutOrder = props.LayoutOrder,
	}, {
		Heading = e(Text, {
			tag = "size-full-0 auto-y text-title-large content-emphasis text-align-x-left",
			Text = "Recently published",
			LayoutOrder = headingOrder,
		}),
		Body = body,
	})
end

return Recent
