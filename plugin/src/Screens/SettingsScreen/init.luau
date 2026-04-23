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
local View = Foundation.View
local ButtonVariant = Foundation.Enums.ButtonVariant
local IconName = Foundation.Enums.IconName
local InputSize = Foundation.Enums.InputSize

local e = React.createElement

local NAMING_CONVENTIONS: { string } =
	table.freeze({ "Original", "PascalCase", "camelCase", "snake_case", "kebab-case" })
local SIDEBAR_MODES: { string } = table.freeze({ "Auto", "Expanded", "Compact" })
local PACKAGE_TYPES_MODES: { string } = table.freeze({ "Parser", "Regex" })

local function SettingsScreen()
	local state = SettingsStore.useSettings()
	local nextOrder = createNextOrder()

	local onNamingConventionChange = React.useCallback(function(value: any)
		SettingsStore.setSetting("namingConvention", value)
	end, {})

	local onReduceMotionChange = React.useCallback(function(value: any)
		SettingsStore.setSetting("reduceMotion", value)
	end, {})

	local onSidebarModeChange = React.useCallback(function(value: any)
		SettingsStore.setSetting("sidebarMode", value)
	end, {})

	local onPackageTypesModeChange = React.useCallback(function(value: any)
		SettingsStore.setSetting("packageTypesMode", value)
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

				PackageTypesMode = e(Setting, {
					name = "Wally Type Exports",
					description = "Parser is stricter and handles unusual Luau source; Regex matches the wally-package-types behavior.",
					value = state.packageTypesMode,
					onChange = onPackageTypesModeChange,
					options = PACKAGE_TYPES_MODES,
					LayoutOrder = nextOrder(),
				}),

				VerboseLogging = e(Setting, {
					name = "Verbose Logging",
					description = "Enable detailed diagnostic logging in the Output window",
					value = state.verboseLogging,
					onChange = onVerboseLoggingChange,
					LayoutOrder = nextOrder(),
				}),
			}),
		}),
	})
end

return SettingsScreen
