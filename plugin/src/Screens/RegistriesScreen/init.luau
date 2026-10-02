--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const React = require(StudioDiscover.Packages.React)

const Content = require(StudioDiscover.Source.Common.Content)
const Navigation = require(StudioDiscover.Source.Navigation)
const Screen = require(StudioDiscover.Source.Common.Screen)
const Setting = require(StudioDiscover.Source.Screens.SettingsScreen.Setting)
const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const settingToggle = require(StudioDiscover.Source.Screens.SettingsScreen.settingToggle)

const e = React.createElement

-- Turns each registry on or off for search, metadata, and installs.
const function RegistriesScreen()
	const registries = SettingsStore.useSettings().registries
	const nextOrder = createNextOrder()

	return e(Screen, {
		title = "Registries",
		onBack = Navigation.popScreen,
	}, {
		Body = e(Content, {}, {
			Wally = e(Setting, {
				name = "Wally",
				description = "Browse and install packages from the Wally registry (wally.run).",
				control = settingToggle(registries.wally, function(enabled)
					SettingsStore.setSetting("registries", { wally = enabled, pesde = registries.pesde })
				end),
				LayoutOrder = nextOrder(),
			}),

			Pesde = e(Setting, {
				name = "pesde",
				description = "Browse and install packages from the pesde registry (pesde.dev).",
				control = settingToggle(registries.pesde, function(enabled)
					SettingsStore.setSetting("registries", { wally = registries.wally, pesde = enabled })
				end),
				LayoutOrder = nextOrder(),
			}),
		}),
	})
end

return RegistriesScreen
