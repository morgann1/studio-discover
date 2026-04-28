--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Charm = require(StudioDiscover.Packages.Charm)
local ReactCharm = require(StudioDiscover.Packages.ReactCharm)
local gt = require(StudioDiscover.Packages.GreenTea)

local createLogger = require(StudioDiscover.Source.Util.createLogger)
local createPluginSettingsStore = require(StudioDiscover.Source.Plugin.createPluginSettingsStore)

export type NamingConvention = "Original" | "PascalCase" | "camelCase" | "snake_case" | "kebab-case"
export type SidebarMode = "Auto" | "Expanded" | "Compact"

export type DisplayNameRule = {
	name: string,
	displayName: string,
}

export type RegistryEnableMap = {
	wally: boolean,
	pesde: boolean,
}

export type SettingsState = {
	namingConvention: NamingConvention,
	displayNames: { DisplayNameRule },
	reduceMotion: boolean,
	sidebarMode: SidebarMode,
	verboseLogging: boolean,
	confirmBeforeInstall: boolean,
	registries: RegistryEnableMap,
}

local DEFAULTS: SettingsState = table.freeze({
	namingConvention = "Original" :: NamingConvention,
	displayNames = table.freeze({}) :: { DisplayNameRule },
	reduceMotion = false,
	sidebarMode = "Auto" :: SidebarMode,
	verboseLogging = false,
	confirmBeforeInstall = true,
	registries = table.freeze({ wally = true, pesde = true }) :: RegistryEnableMap,
})

local function check<T>(type_: T): (value: any) -> (boolean, any?)
	local built = gt.build(type_)
	return function(value)
		return built:matches(value)
	end
end

local VALIDATORS = {
	namingConvention = check(
		gt.union(
			gt.literal("Original"),
			gt.literal("PascalCase"),
			gt.literal("camelCase"),
			gt.literal("snake_case"),
			gt.literal("kebab-case")
		)
	),
	displayNames = check(gt.array(gt.table({
		name = gt.string(),
		displayName = gt.string(),
		[gt.any()] = gt.never(),
	}))),
	reduceMotion = check(gt.boolean()),
	sidebarMode = check(gt.union(gt.literal("Auto"), gt.literal("Expanded"), gt.literal("Compact"))),
	verboseLogging = check(gt.boolean()),
	confirmBeforeInstall = check(gt.boolean()),
	registries = check(gt.table({
		wally = gt.boolean(),
		pesde = gt.boolean(),
		[gt.any()] = gt.never(),
	})),
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

local function resetToDefaults()
	local store = get()
	store.setStorage(DEFAULTS)
end

return table.freeze({
	get = get,
	useSettings = useSettings,
	setSetting = setSetting,
	resetToDefaults = resetToDefaults,
	DEFAULTS = DEFAULTS,
})
