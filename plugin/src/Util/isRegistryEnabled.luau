--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const types = require(StudioDiscover.Libraries.Core.types)

-- Whether the user left `registry` turned on in Settings.
const function isRegistryEnabled(enabled: SettingsStore.RegistryEnableMap, registry: types.Registry): boolean
	return if registry == "pesde" then enabled.pesde else enabled.wally
end

return isRegistryEnabled
