--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const ConfirmDialog = require(StudioDiscover.Source.Common.ConfirmDialog)
const Content = require(StudioDiscover.Source.Common.Content)
const LayoutContext = require(StudioDiscover.Source.Common.LayoutContext)
const Navigation = require(StudioDiscover.Source.Navigation)
const Screen = require(StudioDiscover.Source.Common.Screen)
const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const isRegistryEnabled = require(StudioDiscover.Source.Util.isRegistryEnabled)
const registries = require(StudioDiscover.Libraries.Core.registries)
const registryLabel = require(StudioDiscover.Source.Util.registryLabel)
const registryMark = require(StudioDiscover.Source.Util.registryMark)

const settingDropdown = require(script.settingDropdown)

const Button = Foundation.Button
const List = Foundation.List
const Text = Foundation.Text
const View = Foundation.View
const ButtonVariant = Foundation.Enums.ButtonVariant
const InputSize = Foundation.Enums.InputSize

const e = React.createElement

-- Rows sit flush with the section headings above them.
const UNCONTAINED = { isContained = false, hasMargin = false }

-- Who runs each registry.
const MAINTAINERS: { [coreTypes.Registry]: string } = {
	wally = "Uplift Games",
	pesde = "daimond113",
}

const function setRegistryEnabled(
	enabled: SettingsStore.RegistryEnableMap,
	registry: coreTypes.Registry,
	value: boolean
)
	SettingsStore.setSetting("registries", {
		wally = if registry == "wally" then value else enabled.wally,
		pesde = if registry == "pesde" then value else enabled.pesde,
	})
end

const function toggle(isChecked: boolean, onChanged: (value: boolean) -> ())
	return {
		type = "Toggle",
		isChecked = isChecked,
		onActivated = onChanged,
	}
end

const function heading(text: string, layoutOrder: number): React.Node
	return e(Text, {
		tag = "size-full-0 auto-y text-title-large content-emphasis text-align-x-left padding-top-medium",
		Text = text,
		LayoutOrder = layoutOrder,
	})
end

-- The sources to read from, then how installs behave, then the plugin itself.
const function SettingsScreen()
	const settings = SettingsStore.useSettings()
	const layout = LayoutContext.useLayout()
	const isConfirmingReset, setIsConfirmingReset = React.useState(false)
	const nextOrder = createNextOrder()

	const function closeReset()
		setIsConfirmingReset(false)
	end

	const sources: { [string]: React.Node } = {}
	for index, registry in registries do
		sources[registry] = e(List.Item, {
			leading = registryMark(registry),
			title = registryLabel(registry),
			description = `by {MAINTAINERS[registry]}`,
			input = toggle(isRegistryEnabled(settings.registries, registry), function(value)
				setRegistryEnabled(settings.registries, registry, value)
			end),
			LayoutOrder = index,
		})
	end

	const namingDropdown = settingDropdown(
		settings.namingConvention,
		SettingsStore.NAMING_CONVENTIONS,
		function(value: SettingsStore.NamingConvention)
			SettingsStore.setSetting("namingConvention", value)
		end,
		if layout.isWide then UDim.new(0, 180) else UDim.new(1, 0)
	)

	const ruleCount = #settings.displayNames

	return e(Screen, {}, {
		Body = e(Content, {}, {
			SourcesHeading = heading("Sources", nextOrder()),
			Sources = e(List.Root, {
				size = InputSize.Medium,
				isContained = UNCONTAINED,
				LayoutOrder = nextOrder(),
			}, sources),

			InstallingHeading = heading("Installing", nextOrder()),
			Installing = e(List.Root, {
				size = InputSize.Medium,
				isContained = UNCONTAINED,
				LayoutOrder = nextOrder(),
			}, {
				ConfirmBeforeInstall = e(List.Item, {
					title = "Confirm before install",
					description = "Ask before Discover writes a package into this place.",
					input = toggle(settings.confirmBeforeInstall, function(value)
						SettingsStore.setSetting("confirmBeforeInstall", value)
					end),
					LayoutOrder = 1,
				}),
				NamingConvention = e(List.Item, {
					title = "Naming convention",
					description = "How package names read in lists, and the names new installs get.",
					trailing = if layout.isWide then namingDropdown else nil,
					LayoutOrder = 2,
				}),
				-- In a narrow widget, the dropdown is too wide to share the row, so it gets its own.
				NamingDropdown = not layout.isWide and e(View, {
					tag = "size-full-0 auto-y padding-bottom-medium",
					LayoutOrder = 3,
				}, {
					Dropdown = namingDropdown,
				}),
				DisplayNames = e(List.Item, {
					title = "Display names",
					description = "Give specific packages a fixed name when they install.",
					trailing = e(Text, {
						tag = "auto-xy text-body-medium content-muted",
						Text = tostring(ruleCount),
					}),
					onActivated = function()
						Navigation.pushScreen({ name = "DisplayNames" })
					end,
					LayoutOrder = 4,
				}),
			}),

			PluginHeading = heading("Plugin", nextOrder()),
			Plugin = e(List.Root, {
				size = InputSize.Medium,
				isContained = UNCONTAINED,
				LayoutOrder = nextOrder(),
			}, {
				ReduceMotion = e(List.Item, {
					title = "Reduce motion",
					description = "Turn off animations in Discover.",
					input = toggle(settings.reduceMotion, function(value)
						SettingsStore.setSetting("reduceMotion", value)
					end),
					LayoutOrder = 1,
				}),
				VerboseLogging = e(List.Item, {
					title = "Verbose logging",
					description = "Write every step to the Output window, for reporting a problem.",
					input = toggle(settings.verboseLogging, function(value)
						SettingsStore.setSetting("verboseLogging", value)
					end),
					LayoutOrder = 2,
				}),
			}),

			Reset = e(View, {
				tag = "size-full-0 auto-y padding-y-medium",
				LayoutOrder = nextOrder(),
			}, {
				Button = e(Button, {
					text = "Reset to defaults",
					variant = ButtonVariant.Alert,
					size = InputSize.Small,
					onActivated = function()
						setIsConfirmingReset(true)
					end,
				}),
			}),

			ConfirmResetDialog = isConfirmingReset and e(ConfirmDialog, {
				title = "Reset settings?",
				body = "This restores every setting to its default and clears the display names. It can't be undone.",
				confirmText = "Reset",
				isDestructive = true,
				onConfirm = function()
					SettingsStore.resetToDefaults()
					closeReset()
				end,
				onCancel = closeReset,
			}),
		}),
	})
end

return SettingsScreen
