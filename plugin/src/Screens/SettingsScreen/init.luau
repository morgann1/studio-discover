--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Content = require(StudioDiscover.Source.Common.Content)
const Navigation = require(StudioDiscover.Source.Navigation)
const Screen = require(StudioDiscover.Source.Common.Screen)
const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

const Setting = require(script.Setting)
const settingDropdown = require(script.settingDropdown)
const settingToggle = require(script.settingToggle)

const Button = Foundation.Button
const Dialog = Foundation.Dialog
const View = Foundation.View
const ButtonVariant = Foundation.Enums.ButtonVariant
const DialogSize = Foundation.Enums.DialogSize
const IconName = Foundation.Enums.IconName
const InputSize = Foundation.Enums.InputSize
const Orientation = Foundation.Enums.Orientation

const e = React.createElement

const function editButton(text: string, onActivated: () -> ()): React.Node
	return e(Button, {
		text = text,
		icon = IconName.Pencil,
		variant = ButtonVariant.Utility,
		size = InputSize.Small,
		onActivated = onActivated,
	})
end

const function SettingsScreen()
	const settings = SettingsStore.useSettings()
	const isConfirmingReset, setIsConfirmingReset = React.useState(false)
	const nextOrder = createNextOrder()

	const function onResetRequest()
		setIsConfirmingReset(true)
	end

	const function onResetCancel()
		setIsConfirmingReset(false)
	end

	const function onResetConfirm()
		SettingsStore.resetToDefaults()
		setIsConfirmingReset(false)
	end

	return e(Screen, { title = "Settings" }, {
		Body = e(Content, {}, {
			SettingsList = e(View, {
				tag = "size-full-0 auto-y col",
			}, {
				DisplayNames = e(Setting, {
					name = "Display Names",
					description = "Customize how specific packages are labeled across the plugin",
					control = editButton("Edit", function()
						Navigation.pushScreen({ name = "DisplayNames" })
					end),
					LayoutOrder = nextOrder(),
				}),

				NamingConvention = e(Setting, {
					name = "Naming Convention",
					description = "How package names are displayed in lists and detail views",
					control = settingDropdown(
						settings.namingConvention,
						SettingsStore.NAMING_CONVENTIONS,
						function(value: SettingsStore.NamingConvention)
							SettingsStore.setSetting("namingConvention", value)
						end
					),
					LayoutOrder = nextOrder(),
				}),

				ReduceMotion = e(Setting, {
					name = "Reduce Motion",
					description = "Disable UI animations. Foundation components still animate.",
					control = settingToggle(settings.reduceMotion, function(value)
						SettingsStore.setSetting("reduceMotion", value)
					end),
					LayoutOrder = nextOrder(),
				}),

				SidebarDisplay = e(Setting, {
					name = "Sidebar Display",
					description = "Auto adjusts with widget width. Expanded shows labels; Compact is icon-only.",
					control = settingDropdown(
						settings.sidebarMode,
						SettingsStore.SIDEBAR_MODES,
						function(value: SettingsStore.SidebarMode)
							SettingsStore.setSetting("sidebarMode", value)
						end
					),
					LayoutOrder = nextOrder(),
				}),

				VerboseLogging = e(Setting, {
					name = "Verbose Logging",
					description = "Enable detailed diagnostic logging in the Output window",
					control = settingToggle(settings.verboseLogging, function(value)
						SettingsStore.setSetting("verboseLogging", value)
					end),
					LayoutOrder = nextOrder(),
				}),

				ConfirmBeforeInstall = e(Setting, {
					name = "Confirm Before Install",
					description = "Show a confirmation dialog before installing a package",
					control = settingToggle(settings.confirmBeforeInstall, function(value)
						SettingsStore.setSetting("confirmBeforeInstall", value)
					end),
					LayoutOrder = nextOrder(),
				}),

				Registries = e(Setting, {
					name = "Registries",
					description = "Choose which registries Studio Discover will browse and install from",
					control = editButton("Edit", function()
						Navigation.pushScreen({ name = "Registries" })
					end),
					LayoutOrder = nextOrder(),
				}),

				ResetAll = e(Setting, {
					name = "Reset to Defaults",
					description = "Restore every setting to its default and clear display name overrides",
					control = e(Button, {
						text = "Reset",
						variant = ButtonVariant.Utility,
						size = InputSize.Small,
						onActivated = onResetRequest,
					}),
					LayoutOrder = nextOrder(),
				}),
			}),

			ConfirmResetDialog = isConfirmingReset
				and e(Dialog.Root, {
					size = DialogSize.Small,
					hasBackdrop = true,
					onClose = onResetCancel,
				}, {
					DialogTitle = e(Dialog.Title, {
						text = "Reset settings?",
					}),
					DialogContent = e(Dialog.Content, {}, {
						Body = e(Dialog.Text, {
							Text = "This restores every setting to its default and clears any display name overrides. This can't be undone.",
						}),
					}),
					DialogActions = e(Dialog.Actions, {
						orientation = Orientation.Horizontal,
						actions = {
							{ text = "Cancel", variant = ButtonVariant.Standard, onActivated = onResetCancel },
							{ text = "Reset", variant = ButtonVariant.Alert, onActivated = onResetConfirm },
						},
					}),
				}),
		}),
	})
end

return SettingsScreen
