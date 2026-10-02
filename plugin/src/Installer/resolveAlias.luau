--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const formatName = require(StudioDiscover.Source.Util.formatName)

const logger = createLogger.createLogger("installer.alias")

--[[
	Returns the alias a new root gets: the user's display-name rule for the package if
		one is set, otherwise the package name in the user's naming convention.
]]
const function resolveAlias(name: string): string
	const settings = SettingsStore.getSettings()

	for _, rule in settings.displayNames do
		if rule.name == name and rule.displayName ~= "" then
			logger.info(`alias "{name}" overridden to "{rule.displayName}" (display-name rule)`)
			return rule.displayName
		end
	end

	return formatName(name, settings.namingConvention)
end

return resolveAlias
