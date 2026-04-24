--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local Content = require(StudioDiscover.Source.Common.Content)
local Navigation = require(StudioDiscover.Source.Navigation)
local Screen = require(StudioDiscover.Source.Common.Screen)
local SettingsStore = require(StudioDiscover.Source.SettingsStore)
local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

local Setting = require(script.Setting)

local Button = Foundation.Button
local Dialog = Foundation.Dialog
local View = Foundation.View
local ButtonVariant = Foundation.Enums.ButtonVariant
local DialogSize = Foundation.Enums.DialogSize
local IconName = Foundation.Enums.IconName
local InputSize = Foundation.Enums.InputSize
local Orientation = Foundation.Enums.Orientation

local e = React.createElement

local NAMING_CONVENTIONS: { string } =
	table.freeze({ "Original", "PascalCase", "camelCase", "snake_case", "kebab-case" })
local SIDEBAR_MODES: { string } = table.freeze({ "Auto", "Expanded", "Compact" })

local function SettingsScreen()
	local state = SettingsStore.useSettings()
	local nextOrder = createNextOrder()

	local isConfirmingReset, setIsConfirmingReset = React.useState(false)

	local onResetRequest = React.useCallback(function()
		setIsConfirmingReset(true)
	end, {})

	local onResetCancel = React.useCallback(function()
		setIsConfirmingReset(false)
	end, {})

	local onResetConfirm = React.useCallback(function()
		SettingsStore.resetToDefaults()
		setIsConfirmingReset(false)
	end, {})

	local onNamingConventionChange = React.useCallback(function(value: any)
		SettingsStore.setSetting("namingConvention", value)
	end, {})

	local onReduceMotionChange = React.useCallback(function(value: any)
		SettingsStore.setSetting("reduceMotion", value)
	end, {})

	local onSidebarModeChange = React.useCallback(function(value: any)
		SettingsStore.setSetting("sidebarMode", value)
	end, {})

	local onVerboseLoggingChange = React.useCallback(function(value: any)
		SettingsStore.setSetting("verboseLogging", value)
	end, {})

	local onEditDisplayNames = React.useCallback(function()
		Navigation.pushScreen("DisplayNames")
	end, {})

	local editButton: React.ReactNode = e(Button, {
		text = "Edit",
		icon = IconName.Pencil,
		variant = ButtonVariant.Utility,
		size = InputSize.Small,
		onActivated = onEditDisplayNames,
	})

	local resetButton: React.ReactNode = e(Button, {
		text = "Reset",
		variant = ButtonVariant.Utility,
		size = InputSize.Small,
		onActivated = onResetRequest,
	})

	local confirmDialog: React.ReactNode = nil
	if isConfirmingReset then
		confirmDialog = e(Dialog.Root, {
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
		})
	end

	return e(Screen, { title = "Settings" }, {
		Body = e(Content, {}, {
			SettingsList = e(View, {
				tag = "size-full-0 auto-y col",
			}, {
				DisplayNames = e(Setting, {
					name = "Display Names",
					description = "Customize how specific packages are labeled across the plugin",
					input = editButton,
					LayoutOrder = nextOrder(),
				}),

				NamingConvention = e(Setting, {
					name = "Naming Convention",
					description = "How package names are displayed in lists and detail views",
					value = state.namingConvention,
					onChange = onNamingConventionChange,
					options = NAMING_CONVENTIONS,
					LayoutOrder = nextOrder(),
				}),

				ReduceMotion = e(Setting, {
					name = "Reduce Motion",
					description = "Disable UI animations. Foundation components still animate.",
					value = state.reduceMotion,
					onChange = onReduceMotionChange,
					LayoutOrder = nextOrder(),
				}),

				SidebarDisplay = e(Setting, {
					name = "Sidebar Display",
					description = "Auto adjusts with widget width. Expanded shows labels; Compact is icon-only.",
					value = state.sidebarMode,
					onChange = onSidebarModeChange,
					options = SIDEBAR_MODES,
					LayoutOrder = nextOrder(),
				}),

				VerboseLogging = e(Setting, {
					name = "Verbose Logging",
					description = "Enable detailed diagnostic logging in the Output window",
					value = state.verboseLogging,
					onChange = onVerboseLoggingChange,
					LayoutOrder = nextOrder(),
				}),

				ResetAll = e(Setting, {
					name = "Reset to Defaults",
					description = "Restore every setting to its default and clear display name overrides",
					input = resetButton,
					LayoutOrder = nextOrder(),
				}),
			}),
			ConfirmResetDialog = confirmDialog,
		}),
	})
end

return SettingsScreen
