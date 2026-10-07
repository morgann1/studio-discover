--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const exhaustiveMatch = require(StudioDiscover.Libraries.Core.exhaustiveMatch)
const types = require(StudioDiscover.Libraries.Core.types)

-- Whether the user left `registry` turned on in Settings.
const function isRegistryEnabled(enabled: SettingsStore.RegistryEnableMap, registry: types.Registry): boolean
	if registry == "wally" then
		return enabled.wally
	elseif registry == "pesde" then
		return enabled.pesde
	elseif registry == "nevermore" then
		return enabled.nevermore ~= false
	end

	return exhaustiveMatch(registry)
end

return isRegistryEnabled
