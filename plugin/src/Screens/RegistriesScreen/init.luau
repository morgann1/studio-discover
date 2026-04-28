--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local React = require(StudioDiscover.Packages.React)

local Content = require(StudioDiscover.Source.Common.Content)
local Navigation = require(StudioDiscover.Source.Navigation)
local Screen = require(StudioDiscover.Source.Common.Screen)
local SettingsStore = require(StudioDiscover.Source.SettingsStore)
local Setting = require(StudioDiscover.Source.Screens.SettingsScreen.Setting)
local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

local e = React.createElement

type RegistryKey = "wally" | "pesde"

local function setRegistry(prev: SettingsStore.RegistryEnableMap, registry: RegistryKey, enabled: boolean)
	local next_ = table.clone(prev)
	next_[registry] = enabled
	SettingsStore.setSetting("registries", next_)
end

local function RegistriesScreen()
	local settings = SettingsStore.useSettings()
	local registries = settings.registries

	local onWallyChange = React.useCallback(function(value: any)
		setRegistry(registries, "wally", value)
	end, { registries } :: { any })

	local onPesdeChange = React.useCallback(function(value: any)
		setRegistry(registries, "pesde", value)
	end, { registries } :: { any })

	local nextOrder = createNextOrder()

	return e(Screen, {
		title = "Registries",
		onBack = Navigation.popScreen,
	}, {
		Body = e(Content, {}, {
			Wally = e(Setting, {
				name = "Wally",
				description = "Browse and install packages from the Wally registry (wally.run).",
				value = registries.wally,
				onChange = onWallyChange,
				LayoutOrder = nextOrder(),
			}),

			Pesde = e(Setting, {
				name = "pesde",
				description = "Browse and install packages from the pesde registry (pesde.dev).",
				value = registries.pesde,
				onChange = onPesdeChange,
				LayoutOrder = nextOrder(),
			}),
		}),
	})
end

return RegistriesScreen
