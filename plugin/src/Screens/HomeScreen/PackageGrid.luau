--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const CompactContext = require(StudioDiscover.Source.Common.CompactContext)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const types = require(StudioDiscover.Libraries.Core.types)

const PackageCard = require(script.Parent.PackageCard)

const View = Foundation.View

const e = React.createElement

const function renderCard(pkg: types.PackageBrief, layoutOrder: number?): React.Node
	return e(PackageCard, {
		registries = pkg.registries,
		scope = pkg.scope,
		name = pkg.name,
		description = pkg.description,
		latestVersion = pkg.latestVersion,
		LayoutOrder = layoutOrder,
	})
end

-- Package cards in two columns, or one when the sidebar is compact.
const function PackageGrid(props: {
	read packages: { types.PackageBrief },
	read LayoutOrder: number?,
})
	const compact = CompactContext.useCompact()
	const nextOrder = createNextOrder()
	const cards: { [string]: React.Node } = {}

	if compact then
		for _, pkg in props.packages do
			cards[`{pkg.scope}/{pkg.name}`] = renderCard(pkg, nextOrder())
		end
	else
		for i = 1, #props.packages, 2 do
			const left = props.packages[i]
			const right = props.packages[i + 1]
			const nextCellOrder = createNextOrder()

			cards[`row_{i}`] = e(View, {
				tag = "size-full-0 auto-y row align-y-top gap-medium",
				LayoutOrder = nextOrder(),
			}, {
				Left = e(View, {
					tag = "grow auto-y",
					LayoutOrder = nextCellOrder(),
				}, {
					Card = renderCard(left),
				}),
				Right = e(View, {
					tag = "grow auto-y",
					LayoutOrder = nextCellOrder(),
				}, {
					Card = right ~= nil and renderCard(right),
				}),
			})
		end
	end

	return e(View, {
		tag = "size-full-0 auto-y col gap-medium",
		LayoutOrder = props.LayoutOrder,
	}, cards)
end

return PackageGrid
