local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)

export type NamingConvention = "PascalCase" | "Normal"

export type SettingsData = {
	namingConvention: NamingConvention,
}

export type SettingsContext = {
	settings: SettingsData,
	setSetting: (key: string, value: any) -> (),
}

local DEFAULT_SETTINGS: SettingsData = {
	namingConvention = "Normal",
}

local Context = React.createContext(nil :: SettingsContext?)

local STORAGE_KEY = "DiscoverSettings"

local function loadSettings(pluginInstance: Plugin?): SettingsData
	if not pluginInstance then
		return table.clone(DEFAULT_SETTINGS)
	end
	local ok, saved = pcall(function()
		return pluginInstance:GetSetting(STORAGE_KEY)
	end)
	if ok and typeof(saved) == "table" then
		local merged = table.clone(DEFAULT_SETTINGS)
		for k, v in saved do
			if merged[k] ~= nil then
				merged[k] = v
			end
		end
		return merged
	end
	return table.clone(DEFAULT_SETTINGS)
end

local function saveSettings(pluginInstance: Plugin?, data: SettingsData)
	if not pluginInstance then
		return
	end
	pcall(function()
		pluginInstance:SetSetting(STORAGE_KEY, data)
	end)
end

local function SettingsProvider(props: { plugin: Plugin?, children: any })
	local settings, setSettings = React.useState(function()
		return loadSettings(props.plugin)
	end)

	local setSetting = React.useCallback(function(key: string, value: any)
		setSettings(function(prev)
			local new = table.clone(prev)
			new[key] = value
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
	end, { settings, setSetting })

	return React.createElement(Context.Provider, {
		value = value,
	}, props.children)
end

local function useSettings(): SettingsContext
	local ctx = React.useContext(Context)
	assert(ctx, "useSettings must be used within a SettingsProvider")
	return ctx
end

local function toPascalCase(str: string): string
	return (str:gsub("(%a)([%w]*)", function(first, rest)
		return first:upper() .. rest
	end):gsub("[-_]+", ""))
end

local function formatPackageName(name: string, convention: NamingConvention): string
	if convention == "PascalCase" then
		return toPascalCase(name)
	else
		return name
	end
end

return {
	SettingsProvider = SettingsProvider,
	useSettings = useSettings,
	formatPackageName = formatPackageName,
}
