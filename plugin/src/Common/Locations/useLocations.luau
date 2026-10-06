--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Installer = require(StudioDiscover.Source.Installer)
const Navigation = require(StudioDiscover.Source.Navigation)
const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const isRegistryEnabled = require(StudioDiscover.Source.Util.isRegistryEnabled)
const registries = require(StudioDiscover.Libraries.Core.registries)
const registryLabel = require(StudioDiscover.Source.Util.registryLabel)

-- One place the sidebar or the location menu can switch to.
export type Location = {
	read key: string,
	read text: string,
	read route: Navigation.Route,
	read registry: coreTypes.Registry?,
	read count: number?,
	read isCountEmphasized: boolean,
	read isSelected: boolean,
}

export type Locations = {
	read thisPlace: { Location },
	read sources: { Location },
}

const function isSameLocation(a: Navigation.Route, b: Navigation.Route): boolean
	if a.name == "Source" and b.name == "Source" then
		return a.registry == b.registry
	end

	return a.name == b.name
end

--[[
	The locations to list: Installed and Updates with their counts, then every
		enabled source. The selected one is the location at the bottom of the history,
		so it stays selected while the user is on a package page opened from it.
]]
const function useLocations(): Locations
	const history = Navigation.useHistory()
	const installed = Installer.useInstalledRoots()
	const updates = Installer.useUpdates()
	const enabled = SettingsStore.useSettings().registries

	const current = history.stack[1].route

	const function location(
		key: string,
		text: string,
		route: Navigation.Route,
		count: number?,
		isCountEmphasized: boolean,
		registry: coreTypes.Registry?
	): Location
		return {
			key = key,
			text = text,
			route = route,
			registry = registry,
			count = count,
			isCountEmphasized = isCountEmphasized,
			isSelected = isSameLocation(current, route),
		}
	end

	const sources: { Location } = {}
	for _, registry in registries do
		if not isRegistryEnabled(enabled, registry) then
			continue
		end

		const route: Navigation.Route = { name = "Source", registry = registry }
		table.insert(sources, location(registry, registryLabel(registry), route, nil, false, registry))
	end

	const installedCount = if not installed.loading and #installed.roots > 0 then #installed.roots else nil
	const updatesCount = if #updates.updates > 0 then #updates.updates else nil

	return {
		thisPlace = {
			location("Installed", "Installed", { name = "Installed" }, installedCount, false),
			location("Updates", "Updates", { name = "Updates" }, updatesCount, true),
		},
		sources = sources,
	}
end

return useLocations
