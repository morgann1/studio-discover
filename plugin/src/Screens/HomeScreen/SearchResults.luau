--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local Content = require(StudioDiscover.Source.Common.Content)
local useSearchPackages = require(StudioDiscover.Source.Api.useSearchPackages)

local PackageCard = require(script.Parent.PackageCard)

local Empty = Foundation.Empty
local Loading = Foundation.Loading
local Text = Foundation.Text
local View = Foundation.View

local e = React.createElement

type Props = {
	query: string,
	state: useSearchPackages.SearchState,
}

local function SearchResults(props: Props)
	local state = props.state

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

	local data = state.data
	if data == nil or #data == 0 then
		return e(View, {
			tag = "size-full align-x-center align-y-center",
		}, {
			EmptyState = e(Empty, {
				text = `No packages matching "{props.query}"`,
			}),
		})
	end

	local cards: { [string]: any } = {}
	for i, pkg in data do
		cards[`{pkg.registry}::{pkg.scope}/{pkg.name}`] = e(PackageCard, {
			registry = pkg.registry,
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
