--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Navigation = require(StudioDiscover.Source.Navigation)
const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const exhaustiveMatch = require(StudioDiscover.Libraries.Core.exhaustiveMatch)
const formatName = require(StudioDiscover.Source.Util.formatName)
const registryLabel = require(StudioDiscover.Source.Util.registryLabel)

-- The name a screen goes by in the header and the breadcrumb, such as "Wally" or "Knit".
const function routeTitle(route: Navigation.Route, namingConvention: SettingsStore.NamingConvention): string
	if route.name == "Source" then
		return registryLabel(route.registry)
	elseif route.name == "Package" then
		return formatName(route.target.name, namingConvention)
	elseif route.name == "Installed" then
		return "Installed"
	elseif route.name == "Updates" then
		return "Updates"
	elseif route.name == "Search" then
		return "Search"
	elseif route.name == "Settings" then
		return "Settings"
	elseif route.name == "DisplayNames" then
		return "Display names"
	end

	return exhaustiveMatch(route.name)
end

return routeTitle
