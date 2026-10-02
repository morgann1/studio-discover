--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Charm = require(StudioDiscover.Packages.Charm)
const GreenTea = require(StudioDiscover.Packages.GreenTea)

const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const createPluginSettingsStore = require(StudioDiscover.Source.Plugin.createPluginSettingsStore)
const useAtom = require(StudioDiscover.Source.Common.useAtom)

export type NamingConvention = "Original" | "PascalCase" | "camelCase" | "snake_case" | "kebab-case"
export type SidebarMode = "Auto" | "Expanded" | "Compact"

export type DisplayNameRule = {
	read name: string,
	read displayName: string,
}

export type RegistryEnableMap = {
	read wally: boolean,
	read pesde: boolean,
}

export type SettingsState = {
	read namingConvention: NamingConvention,
	read displayNames: { DisplayNameRule },
	read reduceMotion: boolean,
	read sidebarMode: SidebarMode,
	read verboseLogging: boolean,
	read confirmBeforeInstall: boolean,
	read registries: RegistryEnableMap,
}

const NAMING_CONVENTIONS: { NamingConvention } = { "Original", "PascalCase", "camelCase", "snake_case", "kebab-case" }
const SIDEBAR_MODES: { SidebarMode } = { "Auto", "Expanded", "Compact" }

const DEFAULTS: SettingsState = {
	namingConvention = "Original",
	displayNames = {},
	reduceMotion = false,
	sidebarMode = "Auto",
	verboseLogging = false,
	confirmBeforeInstall = true,
	registries = { wally = true, pesde = true },
}

const function oneOf<T>(options: { T })
	const literals = {}
	for _, option in options do
		table.insert(literals, GreenTea.literal(option))
	end

	return GreenTea.union(table.unpack(literals))
end

const function check<T>(shape: T): (value: unknown) -> boolean
	const built = GreenTea.build(shape)

	return function(value)
		return (built:matches(value))
	end
end

const VALIDATORS = {
	namingConvention = check(oneOf(NAMING_CONVENTIONS)),
	displayNames = check(GreenTea.array(GreenTea.table({
		name = GreenTea.string(),
		displayName = GreenTea.string(),
		[GreenTea.any()] = GreenTea.never(),
	}))),
	reduceMotion = check(GreenTea.boolean()),
	sidebarMode = check(oneOf(SIDEBAR_MODES)),
	verboseLogging = check(GreenTea.boolean()),
	confirmBeforeInstall = check(GreenTea.boolean()),
	registries = check(GreenTea.table({
		wally = GreenTea.boolean(),
		pesde = GreenTea.boolean(),
		[GreenTea.any()] = GreenTea.never(),
	})),
}

const store = createPluginSettingsStore("DiscoverSettings", DEFAULTS, VALIDATORS)

Charm.effect(function()
	if not store.getIsLoading() then
		createLogger.setVerbose(store.getStorage().verboseLogging)
	end
end)

--[[
	Returns the current settings. Inside a Charm selector or effect, it re-runs when
		they change.
]]
const function getSettings(): SettingsState
	return store.getStorage()
end

const function useSettings(): SettingsState
	return useAtom(store.getStorage)
end

-- Replaces one setting, as in `setSetting("reduceMotion", true)`.
const function setSetting<K>(key: K & keyof<SettingsState>, value: index<SettingsState, K>)
	store.setStorage(function(previous)
		const nextSettings = table.clone(previous) :: { [K & keyof<SettingsState>]: index<SettingsState, K> }
		nextSettings[key] = value

		return nextSettings :: SettingsState
	end)
end

const function resetToDefaults()
	store.setStorage(DEFAULTS)
end

const SettingsStore = table.freeze({
	NAMING_CONVENTIONS = NAMING_CONVENTIONS,
	SIDEBAR_MODES = SIDEBAR_MODES,
	getSettings = getSettings,
	useSettings = useSettings,
	setSetting = setSetting,
	resetToDefaults = resetToDefaults,
})

return SettingsStore
