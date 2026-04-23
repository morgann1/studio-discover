--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Charm = require(StudioDiscover.Packages.Charm)
local ReactCharm = require(StudioDiscover.Packages.ReactCharm)
local t = require(StudioDiscover.Packages.t)

local createLogger = require(StudioDiscover.Source.Util.createLogger)
local createPluginSettingsStore = require(StudioDiscover.Source.Plugin.createPluginSettingsStore)

export type NamingConvention = "Original" | "PascalCase" | "camelCase" | "snake_case" | "kebab-case"
export type SidebarMode = "Auto" | "Expanded" | "Compact"
export type PackageTypesMode = "Parser" | "Regex"

export type DisplayNameRule = {
	name: string,
	displayName: string,
}

export type SettingsState = {
	namingConvention: NamingConvention,
	displayNames: { DisplayNameRule },
	packageTypesMode: PackageTypesMode,
	reduceMotion: boolean,
	sidebarMode: SidebarMode,
	verboseLogging: boolean,
}

local DEFAULTS: SettingsState = table.freeze({
	namingConvention = "Original" :: NamingConvention,
	displayNames = table.freeze({}) :: { DisplayNameRule },
	packageTypesMode = "Parser" :: PackageTypesMode,
	reduceMotion = false,
	sidebarMode = "Auto" :: SidebarMode,
	verboseLogging = false,
})

local VALIDATORS = {
	namingConvention = t.literal("Original", "PascalCase", "camelCase", "snake_case", "kebab-case"),
	displayNames = t.array(t.strictInterface({
		name = t.string,
		displayName = t.string,
	})),
	packageTypesMode = t.literal("Parser", "Regex"),
	reduceMotion = t.boolean,
	sidebarMode = t.literal("Auto", "Expanded", "Compact"),
	verboseLogging = t.boolean,
}

local get = Charm.computed(function()
	return createPluginSettingsStore("DiscoverSettings", DEFAULTS, VALIDATORS)
end)

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
