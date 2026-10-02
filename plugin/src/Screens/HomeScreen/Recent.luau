--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

const PackageGrid = require(script.Parent.PackageGrid)
const useRecent = require(script.Parent.useRecent)

const Loading = Foundation.Loading
const Text = Foundation.Text
const View = Foundation.View

const e = React.createElement

-- The latest pesde packages, shown on Home when pesde is enabled.
const function Recent(props: {
	read LayoutOrder: number?,
})
	const state = useRecent()
	const nextOrder = createNextOrder()
	const headingOrder = nextOrder()
	const bodyOrder = nextOrder()

	local body: React.Node
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
		body = e(PackageGrid, {
			packages = state.packages,
			LayoutOrder = bodyOrder,
		})
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
