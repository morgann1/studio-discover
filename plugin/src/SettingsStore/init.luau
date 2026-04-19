--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Charm = require(StudioDiscover.Packages.Charm)
local ReactCharm = require(StudioDiscover.Packages.ReactCharm)
local t = require(StudioDiscover.Packages.t)

local createLogger = require(StudioDiscover.Source.Util.createLogger)
local createPluginSettingsStore = require(StudioDiscover.Source.Plugin.createPluginSettingsStore)

export type NamingConvention = "Original" | "PascalCase" | "camelCase" | "snake_case" | "kebab-case"
export type SidebarMode = "Auto" | "Expanded" | "Compact"

export type SettingsState = {
	namingConvention: NamingConvention,
	checkForUpdates: boolean,
	reduceMotion: boolean,
	sidebarMode: SidebarMode,
	verboseLogging: boolean,
}

local DEFAULTS: SettingsState = table.freeze({
	namingConvention = "Original" :: NamingConvention,
	checkForUpdates = true,
	reduceMotion = false,
	sidebarMode = "Auto" :: SidebarMode,
	verboseLogging = false,
})

local VALIDATORS = {
	namingConvention = t.literal("Original", "PascalCase", "camelCase", "snake_case", "kebab-case"),
	checkForUpdates = t.boolean,
	reduceMotion = t.boolean,
	sidebarMode = t.literal("Auto", "Expanded", "Compact"),
	verboseLogging = t.boolean,
}

local get = Charm.computed(function()
	return createPluginSettingsStore("DiscoverSettings", DEFAULTS, VALIDATORS)
end)

-- Keep the module-level logger verbose flag in sync with the persisted
-- `verboseLogging` setting. Retained in a module-level local so Charm's weak
-- listener table doesn't garbage-collect the effect.
local _disposeVerboseSync = Charm.effect(function()
	local store = get()
	if store.getIsLoading() then
		return
	end
	createLogger.setVerbose(store.getStorage().verboseLogging)
end)

local function useSettings(): SettingsState
	local store = get()
	return ReactCharm.useAtom(store.getStorage)
end

local function setSetting(key: string, value: any)
	local store = get()
	store.setStorage(function(prev)
		local next_: any = table.clone(prev)
		next_[key] = value
		return next_
	end)
end

return table.freeze({
	get = get,
	useSettings = useSettings,
	setSetting = setSetting,
	DEFAULTS = DEFAULTS,
})
