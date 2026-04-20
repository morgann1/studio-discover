--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

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

local function Recent(props: Props)
	local state = useRecent()
	local nextOrder = createNextOrder()

	local children: { [string]: any } = {}

	children.Heading = e(Text, {
		tag = "size-full-0 auto-y text-title-large content-emphasis text-align-x-left",
		Text = "Recently published",
		LayoutOrder = nextOrder(),
	})

	if state.loading then
		children.Spinner = e(View, {
			tag = "size-full-0 auto-y align-x-center padding-medium",
			LayoutOrder = nextOrder(),
		}, {
			Inner = e(Loading, {}),
		})
	elseif state.error ~= nil or #state.packages == 0 then
		children.Empty = e(Text, {
			tag = "size-full-0 auto-y text-body-medium content-muted text-align-x-left",
			Text = state.error or "No recent pesde packages available.",
			LayoutOrder = nextOrder(),
		})
	else
		for _, pkg in state.packages do
			children[`{pkg.registry}::{pkg.scope}/{pkg.name}`] = e(PackageCard, {
				registry = pkg.registry,
				scope = pkg.scope,
				name = pkg.name,
				description = pkg.description,
				latestVersion = pkg.latestVersion,
				LayoutOrder = nextOrder(),
			})
		end
	end

	return e(View, {
		tag = "size-full-0 auto-y col gap-medium",
		LayoutOrder = props.LayoutOrder,
	}, children)
end

return Recent
