--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const React = require(StudioDiscover.Packages.React)

const LoadError = require(StudioDiscover.Source.Common.LoadError)
const Message = require(StudioDiscover.Source.Common.Message)
const Navigation = require(StudioDiscover.Source.Navigation)
const PackageTable = require(StudioDiscover.Source.Common.PackageTable)
const Screen = require(StudioDiscover.Source.Common.Screen)
const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const escapeRichText = require(StudioDiscover.Source.Util.escapeRichText)
const isRegistryEnabled = require(StudioDiscover.Source.Util.isRegistryEnabled)
const registryLabel = require(StudioDiscover.Source.Util.registryLabel)
const useListing = require(StudioDiscover.Source.Api.useListing)
const useSearchPackages = require(StudioDiscover.Source.Api.useSearchPackages)

const e = React.createElement

const function openSettings()
	Navigation.resetScreen({ name = "Settings" })
end

--[[
	One source's packages: its listing, or what matches the docked search row. The
		expanded sidebar searches every source instead.
]]
const function SourceScreen(props: {
	read registry: coreTypes.Registry,
})
	const registry = props.registry
	const label = registryLabel(registry)
	const query, setQuery = React.useState("")
	const enabled = isRegistryEnabled(SettingsStore.useSettings().registries, registry)

	const listing = useListing(registry)
	const results = useSearchPackages(query, if enabled then { registry } else {})
	const isSearching = #query >= 2
	const state = if isSearching then results else listing
	const data = state.data

	local body: React.Node
	if not enabled then
		body = e(Message, {
			text = `{label} is turned off.`,
			action = { text = "Open Settings", onActivated = openSettings },
		})
	elseif state.loading then
		body = e(Message, { text = `Loading {label}...` })
	elseif state.error ~= nil then
		body = e(LoadError, { text = `Couldn't load {label}: {state.error}` })
	elseif data == nil or #data == 0 then
		body = e(Message, {
			text = if isSearching then `No {label} packages match "{query}".` else `{label} listed no packages.`,
		})
	else
		body = e(PackageTable, {
			packages = data,
			showsSource = false,
		})
	end

	return e(Screen, {
		title = escapeRichText(label),
		search = {
			text = query,
			placeholder = `Search {label}`,
			onChanged = setQuery,
		},
	}, {
		Body = body,
	})
end

return SourceScreen
