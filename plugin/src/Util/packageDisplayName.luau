--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const formatName = require(StudioDiscover.Source.Util.formatName)

-- The settings that decide a package's name, a subset of `SettingsStore.SettingsState`.
export type NameSettings = {
	read namingConvention: string,
	read displayNames: { { read name: string, read displayName: string } },
}

--[[
	The name a package goes by in the UI and as an installed root's alias: the user's
		display-name rule for it if one is set, otherwise the name in their naming convention.
]]
const function packageDisplayName(name: string, settings: NameSettings): string
	for _, rule in settings.displayNames do
		if rule.name == name and rule.displayName ~= "" then
			return rule.displayName
		end
	end

	return formatName(name, settings.namingConvention)
end

return packageDisplayName
