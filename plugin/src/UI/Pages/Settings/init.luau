local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)
local StudioComponents = require(Packages.StudioComponents)

local Navigation = require(Discover.Src.UI.Navigation)
local Setting = require(script.Setting)
local createNextOrder = require(Discover.Src.UI.Util.createNextOrder)

local e = React.createElement

local NAMING_CONVENTIONS = { "As-Is", "PascalCase", "camelCase", "snake_case", "kebab-case" }

local function SettingsPage()
	local nextOrder = createNextOrder()

	return e(StudioComponents.ScrollFrame, {
		Size = UDim2.fromScale(1, 1),
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		Layout = {
			ClassName = "UIListLayout",
			SortOrder = Enum.SortOrder.LayoutOrder,
		},
	}, {
		CheckForUpdates = e(Setting, {
			id = "checkForUpdates",
			name = "Check For Updates",
			description = "Notify when a newer version of Discover is available.",
			layoutOrder = nextOrder(),
		}),
		NamingConvention = e(Setting, {
			id = "namingConvention",
			name = "Naming Convention",
			description = "How alias ModuleScripts are named when a package is installed.",
			options = NAMING_CONVENTIONS,
			layoutOrder = nextOrder(),
		}),
		ReduceMotion = e(Setting, {
			id = "reduceMotion",
			name = "Reduce Motion",
			description = "Skip page transition animations.",
			layoutOrder = nextOrder(),
		}),
		VerboseLogging = e(Setting, {
			id = "verboseLogging",
			name = "Verbose Logging",
			description = "Print detailed install progress to the output.",
			layoutOrder = nextOrder(),
		}),
		Overrides = e(Setting, {
			name = "Name Overrides",
			description = "Manage per-package alias overrides.",
			onNavigate = function()
				Navigation.push("Overrides")
			end,
			layoutOrder = nextOrder(),
		}),
	})
end

return SettingsPage
