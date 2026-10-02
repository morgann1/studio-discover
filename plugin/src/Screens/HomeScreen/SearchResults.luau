--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Content = require(StudioDiscover.Source.Common.Content)
const useSearchPackages = require(StudioDiscover.Source.Api.useSearchPackages)

const PackageCard = require(script.Parent.PackageCard)

const Empty = Foundation.Empty
const Loading = Foundation.Loading
const Text = Foundation.Text
const View = Foundation.View

const e = React.createElement

const function SearchResults(props: {
	read query: string,
	read state: useSearchPackages.SearchState,
}): React.Node
	const state = props.state

	if state.loading then
		return e(View, {
			tag = "size-full align-x-center align-y-center",
		}, {
			Spinner = e(Loading, {}),
		})
	end

	if state.error ~= nil then
		return e(View, {
			tag = "size-full align-x-center align-y-center padding-large",
		}, {
			Message = e(Text, {
				tag = "auto-xy text-body-medium content-muted",
				Text = `Couldn't load results: {state.error}`,
			}),
		})
	end

	const data = state.data
	if data == nil or #data == 0 then
		return e(View, {
			tag = "size-full align-x-center align-y-center",
		}, {
			EmptyState = e(Empty, {
				text = `No packages matching "{props.query}"`,
			}),
		})
	end

	const cards: { [string]: React.Node } = {}
	for i, pkg in data do
		cards[`{pkg.scope}/{pkg.name}`] = e(PackageCard, {
			registries = pkg.registries,
			scope = pkg.scope,
			name = pkg.name,
			description = pkg.description,
			latestVersion = pkg.latestVersion,
			LayoutOrder = i,
		})
	end

	return e(Content, {}, cards)
end

return SearchResults
