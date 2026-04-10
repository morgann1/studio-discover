local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)

export type NamingConvention = "PascalCase" | "Normal"

export type SettingsData = {
	namingConvention: NamingConvention,
	-- User-defined display name overrides, keyed by `scope/name` (lowercase).
	-- These take precedence over both the curated overrides table and the
	-- naming convention transform.
	nameOverrides: { [string]: string },
}

export type SettingsContext = {
	settings: SettingsData,
	setSetting: (key: string, value: any) -> (),
}

local DEFAULT_SETTINGS: SettingsData = {
	namingConvention = "Normal",
	nameOverrides = {},
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

-- Hand-curated PascalCase overrides for popular packages whose lowercase
-- Wally name can't be reliably segmented (e.g. "goodsignal" -> "GoodSignal").
-- Keys must be lowercase. Add entries as you discover them.
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

--[[
	Derive a PascalCase display name. Resolution order:
	1. `hint`, if provided and it matches `name` case-insensitively (after
	   stripping separators). This lets callers pass an upstream-canonical
	   name like a GitHub repository segment.
	2. The hand-curated overrides table.
	3. Mechanical first-letter capitalization (handles `foo-bar`/`foo_bar`).
]]
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
	scope: string?,
	overrides: { [string]: string }?,
}

local function formatPackageName(name: string, convention: NamingConvention, options: FormatOptions?): string
	-- User overrides win over everything else, including the naming
	-- convention setting. They are an explicit "I want this name".
	if options and options.overrides and options.scope then
		local key = string.lower(`{options.scope}/{name}`)
		local override = options.overrides[key]
		if override and override ~= "" then
			return override
		end
	end

	if convention == "PascalCase" then
		return toPascalCaseWithHint(name, options and options.hint)
	else
		return name
	end
end

return {
	SettingsProvider = SettingsProvider,
	useSettings = useSettings,
	formatPackageName = formatPackageName,
}
