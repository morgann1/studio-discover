--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const coreTypes = require(StudioDiscover.Libraries.Core.types)
const formatName = require(StudioDiscover.Source.Util.formatName)
const knownNevermoreNames = require(StudioDiscover.Libraries.NevermoreRegistry.knownNames)

-- The settings that decide a package's name, a subset of `SettingsStore.SettingsState`.
export type NameSettings = {
	read namingConvention: string,
	read displayNames: { { read name: string, read displayName: string } },
}

--[[
	The name a package goes by in the UI, and for Wally and pesde as an installed
		root's alias: the user's display-name rule for it if one is set, otherwise the
		name in their naming convention.

	Nevermore packages install under their npm name, which the loader never sees,
		and show by the name of the module people require, such as "CharacterUtils".
		A naming convention would only garble that.
]]
const function packageDisplayName(registry: coreTypes.Registry, name: string, settings: NameSettings): string
	for _, rule in settings.displayNames do
		if rule.name == name and rule.displayName ~= "" then
			return rule.displayName
		end
	end

	if registry == "nevermore" then
		return knownNevermoreNames[name] or name
	end

	return formatName(name, settings.namingConvention)
end

return packageDisplayName
