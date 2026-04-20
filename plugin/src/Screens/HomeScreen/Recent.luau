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
		registry = pkg.registry,
		scope = pkg.scope,
		name = pkg.name,
		description = pkg.description,
		latestVersion = pkg.latestVersion,
	})
end

local function Recent(props: Props)
	local state = useRecent()
	local compact = CompactContext.useCompact()

	local body: React.ReactNode
	if state.loading then
		body = e(View, {
			tag = "size-full-0 auto-y align-x-center padding-medium",
			LayoutOrder = 2,
		}, {
			Inner = e(Loading, {}),
		})
	elseif state.error ~= nil or #state.packages == 0 then
		body = e(Text, {
			tag = "size-full-0 auto-y text-body-medium content-muted text-align-x-left",
			Text = state.error or "No recent pesde packages available.",
			LayoutOrder = 2,
		})
	else
		local cards: { [string]: any } = {}
		if compact then
			local cardOrder = createNextOrder()
			for _, pkg in state.packages do
				cards[`{pkg.registry}::{pkg.scope}/{pkg.name}`] = e(PackageCard, {
					registry = pkg.registry,
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
		body = e(View, {
			tag = "size-full-0 auto-y col gap-medium",
			LayoutOrder = 2,
		}, cards)
	end

	return e(View, {
		tag = "size-full-0 auto-y col gap-medium",
		LayoutOrder = props.LayoutOrder,
	}, {
		Heading = e(Text, {
			tag = "size-full-0 auto-y text-title-large content-emphasis text-align-x-left",
			Text = "Recently published",
			LayoutOrder = 1,
		}),
		Body = body,
	})
end

return Recent
