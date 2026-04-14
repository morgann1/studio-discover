local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)

local e = React.createElement

export type NamingConvention = "Normal" | "PascalCase" | "camelCase" | "snake_case"

export type SettingsData = {
	namingConvention: NamingConvention,
	nameOverrides: { [string]: string },
	checkForUpdates: boolean,
	skipUninstallConfirm: boolean,
	dismissedUpdateVersion: string?,
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
	verboseLogging = false,
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

	return e(Context.Provider, {
		value = value,
	}, props.children)
end

local function useSettings(): SettingsContext
	local settingsContext = React.useContext(Context)
	assert(settingsContext, "useSettings must be used within a SettingsProvider")
	return settingsContext
end

local PASCAL_OVERRIDES: { [string]: string } = {
	goodsignal = "GoodSignal",
	roactrouter = "RoactRouter",
	roactrodux = "RoactRodux",
	roactnavigation = "RoactNavigation",
	testez = "TestEZ",
	wally = "Wally",
}

local function toPascalCase(str: string): string
	return (str:gsub("(%a)([%w]*)", function(first, rest)
		return first:upper() .. rest
	end):gsub("[-_]+", ""))
end

local function toCamelCase(str: string): string
	local pascal = toPascalCase(str)
	return pascal:sub(1, 1):lower() .. pascal:sub(2)
end

local function toSnakeCase(str: string): string
	return (str:gsub("[-]+", "_"):lower())
end

local function toPascalCaseWithHint(name: string, hint: string?): string
	if hint and hint ~= "" then
		local normalizedName = string.lower((string.gsub(name, "[-_]+", "")))
		local normalizedHint = string.lower((string.gsub(hint, "[-_]+", "")))
		if normalizedName == normalizedHint then
			return (string.gsub(hint, "[-_]+", ""))
		end
	end

	local override = PASCAL_OVERRIDES[string.lower(name)]
	if override then
		return override
	end

	return toPascalCase(name)
end

export type FormatOptions = {
	hint: string?,
	overrides: { [string]: string }?,
}

local function formatPackageName(name: string, convention: NamingConvention, options: FormatOptions?): string
	if options and options.overrides then
		local key = string.lower(name)
		local override = options.overrides[key]
		if override and override ~= "" then
			return override
		end
	end

	if convention == "PascalCase" then
		return toPascalCaseWithHint(name, options and options.hint)
	elseif convention == "camelCase" then
		return toCamelCase(name)
	elseif convention == "snake_case" then
		return toSnakeCase(name)
	else
		return name
	end
end

return {
	SettingsProvider = SettingsProvider,
	useSettings = useSettings,
	formatPackageName = formatPackageName,
}
