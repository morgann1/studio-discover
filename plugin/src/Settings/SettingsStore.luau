--!strict

local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)
local formatPackageName = require(Discover.Src.Util.formatPackageName)

local e = React.createElement

export type NamingConvention = formatPackageName.NamingConvention

export type SettingsData = {
	namingConvention: NamingConvention,
	nameOverrides: { [string]: string },
	checkForUpdates: boolean,
	skipUninstallConfirm: boolean,
	dismissedUpdateVersion: string?,
	reduceMotion: boolean,
	verboseLogging: boolean,
}

export type SettingsContext = {
	settings: SettingsData,
	setSetting: (key: string, value: any) -> (),
}

local DEFAULT_SETTINGS: SettingsData = {
	namingConvention = "Normal",
	nameOverrides = {},
	skipUninstallConfirm = false,
	checkForUpdates = true,
	reduceMotion = false,
	verboseLogging = false,
}

local DEFAULT_CONTEXT: SettingsContext = {
	settings = DEFAULT_SETTINGS,
	setSetting = function(_key, _value) end,
}

local Context = React.createContext<<SettingsContext>>(DEFAULT_CONTEXT)

local STORAGE_KEY = "DiscoverSettings"

local function loadSettings(pluginInstance: Plugin?): SettingsData
	if pluginInstance == nil then
		return table.clone(DEFAULT_SETTINGS)
	end
	local ok, saved = pcall(function()
		return pluginInstance:GetSetting(STORAGE_KEY)
	end)
	if ok and typeof(saved) == "table" then
		local merged = table.clone(DEFAULT_SETTINGS)
		local mergedAny = merged :: any
		for k, v in saved :: { [string]: any } do
			if mergedAny[k] ~= nil then
				mergedAny[k] = v
			end
		end
		return merged
	end
	return table.clone(DEFAULT_SETTINGS)
end

local function saveSettings(pluginInstance: Plugin?, data: SettingsData)
	if pluginInstance == nil then
		return
	end
	pcall(function()
		pluginInstance:SetSetting(STORAGE_KEY, data)
	end)
end

local function SettingsProvider(props: { plugin: Plugin?, children: any }): React.ReactNode
	local settings: SettingsData, setSettings = React.useState(function(): SettingsData
		return loadSettings(props.plugin)
	end)

	local setSetting = React.useCallback(function(key: string, value: any)
		setSettings(function(prev)
			local new = table.clone(prev);
			(new :: any)[key] = value
			saveSettings(props.plugin, new)
			return new
		end)
	end, { props.plugin })

	local value: SettingsContext = React.useMemo(function()
		local v: SettingsContext = {
			settings = settings,
			setSetting = setSetting,
		}
		return v
	end, { settings, setSetting } :: { any })

	return e(Context.Provider, {
		value = value,
	}, props.children)
end

local function useSettings(): SettingsContext
	return React.useContext(Context)
end

return {
	SettingsProvider = SettingsProvider,
	useSettings = useSettings,
}
