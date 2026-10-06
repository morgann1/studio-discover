--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const packageDisplayName = require(StudioDiscover.Source.Util.packageDisplayName)

-- Returns the alias a new root gets: the name the UI shows for the package.
const function resolveAlias(name: string): string
	return packageDisplayName(name, SettingsStore.getSettings())
end

return resolveAlias
