--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const LoadError = require(StudioDiscover.Source.Common.LoadError)
const Message = require(StudioDiscover.Source.Common.Message)
const PackageTable = require(StudioDiscover.Source.Common.PackageTable)
const Screen = require(StudioDiscover.Source.Common.Screen)
const SearchStore = require(StudioDiscover.Source.SearchStore)
const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const isRegistryEnabled = require(StudioDiscover.Source.Util.isRegistryEnabled)
const registries = require(StudioDiscover.Libraries.Core.registries)
const registryLabel = require(StudioDiscover.Source.Util.registryLabel)
const useSearchPackages = require(StudioDiscover.Source.Api.useSearchPackages)

const ChipGroup = Foundation.ChipGroup
const View = Foundation.View
const ChipGroupVariant = Foundation.Enums.ChipGroupVariant
const ChipSize = Foundation.Enums.ChipSize

const e = React.createElement

-- The results for the sidebar's search across every enabled source, with a chip per source to narrow them.
const function SearchScreen()
	const query = SearchStore.useQuery()
	const enabled = SettingsStore.useSettings().registries
	const filter, setFilter = React.useState<<coreTypes.Registry?>>(nil)

	const sources: { coreTypes.Registry } = {}
	for _, registry in registries do
		if isRegistryEnabled(enabled, registry) then
			table.insert(sources, registry)
		end
	end

	const state = useSearchPackages(query, sources)
	const data = state.data
	const nextOrder = createNextOrder()

	local body: React.Node
	if #query < 2 then
		body = e(Message, { text = "Type at least two characters to search every source." })
	elseif state.loading then
		body = e(Message, { text = "Searching..." })
	elseif state.error ~= nil then
		body = e(LoadError, { text = `Couldn't search: {state.error}` })
	elseif data == nil then
		body = nil
	else
		const shown: { coreTypes.PackageBrief } = {}
		for _, brief in data do
			if filter == nil or brief.registries[1] == filter then
				table.insert(shown, brief)
			end
		end

		const chips: { Foundation.ChipGroupItem } = {
			{
				text = "All",
				isChecked = filter == nil,
				onActivated = function()
					setFilter(nil)
				end,
			},
		}

		for _, registry in sources do
			table.insert(chips, {
				text = registryLabel(registry),
				isChecked = filter == registry,
				onActivated = function()
					setFilter(registry)
				end,
			})
		end

		body = e(View, {
			tag = "size-full col",
		}, {
			Filters = e(View, {
				tag = "size-full-0 auto-y padding-x-large padding-bottom-medium",
				LayoutOrder = nextOrder(),
			}, {
				Chips = e(ChipGroup, {
					chips = chips,
					size = ChipSize.Small,
					variant = ChipGroupVariant.Row,
				}),
			}),
			Results = e(View, {
				tag = "size-full-0 grow",
				LayoutOrder = nextOrder(),
			}, {
				Table = if #shown > 0
					then e(PackageTable, {
						packages = shown,
						showsSource = true,
					})
					else e(Message, { text = `No packages match "{query}".` }),
			}),
		})
	end

	return e(Screen, {
		search = {
			text = query,
			placeholder = "Search all sources",
			onChanged = SearchStore.setQuery,
		},
	}, {
		Body = body,
	})
end

return SearchScreen
