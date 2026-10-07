--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const packageDisplayName = require(StudioDiscover.Source.Util.packageDisplayName)

-- Returns the alias a new root gets: the name the UI shows for the package.
const function resolveAlias(registry: coreTypes.Registry, name: string): string
	return packageDisplayName(registry, name, SettingsStore.getSettings())
end

return resolveAlias
