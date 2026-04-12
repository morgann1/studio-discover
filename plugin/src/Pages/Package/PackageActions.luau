local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local Text = Foundation.Text
local Button = Foundation.Button
local Dropdown = Foundation.Dropdown
local SystemBanner = Foundation.SystemBanner

local InputSize = Foundation.Enums.InputSize
local ButtonVariant = Foundation.Enums.ButtonVariant
local AlertSeverity = Foundation.Enums.AlertSeverity

local e = React.createElement

type PackageActionsProps = {
	selectedVersion: string?,
	versionItems: { { id: string, text: string } },
	onVersionChanged: (id: string) -> (),
	installStatus: string,
	installError: string?,
	installProgress: string?,
	isDevRealm: boolean,
	isLatestSelected: boolean,
	alreadyInstalled: boolean,
	onInstall: () -> (),
	LayoutOrder: number?,
}

local function PackageActions(props: PackageActionsProps)
	local installButtonText = if props.isDevRealm
		then "Not Supported"
		elseif props.installStatus == "installing" then "Installing..."
		elseif props.installStatus == "installed" or props.alreadyInstalled then "Installed"
		elseif props.installStatus == "partial" then "Installed (with warnings)"
		elseif props.installStatus == "error" then "Retry"
		else "Install"

	local installButtonDisabled = props.isDevRealm
		or props.installStatus == "installing"
		or props.installStatus == "installed"
		or props.installStatus == "partial"
		or props.alreadyInstalled

	return e("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
	}, {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}),

		Row = e("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
			RowLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 8),
			}),
			VersionWrap = e("Frame", {
				Size = UDim2.new(1, 0, 0, 40),
				BackgroundTransparency = 1,
				LayoutOrder = 1,
			}, {
				Flex = e("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
				Dropdown = e(Dropdown.Root, {
					label = "",
					value = props.selectedVersion,
					size = InputSize.Medium,
					width = UDim.new(1, 0),
					onItemChanged = props.onVersionChanged,
					items = props.versionItems,
					maxHeight = 200,
				}),
			}),
			Install = e(Button, {
				text = installButtonText,
				variant = if props.installStatus == "installed"
						or props.installStatus == "partial"
						or props.alreadyInstalled
					then ButtonVariant.Standard
					else ButtonVariant.Emphasis,
				size = InputSize.Medium,
				isDisabled = installButtonDisabled,
				onActivated = props.onInstall,
				LayoutOrder = 2,
			}),
		}),

		OlderVersionBanner = if not props.isLatestSelected
				and props.installStatus == "idle"
				and not props.alreadyInstalled
			then e(SystemBanner, {
				severity = AlertSeverity.Warning,
				title = "Installing an older version",
				description = "The latest version is available in the dropdown above.",
				LayoutOrder = 2,
			})
			else nil,

		InstallProgress = if props.installProgress
			then e(Text, {
				Text = props.installProgress,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				TextWrapped = true,
				tag = "text-caption-small content-muted text-align-x-left",
				LayoutOrder = 3,
			})
			else nil,

		DevRealmNotice = props.isDevRealm and e(SystemBanner, {
			severity = AlertSeverity.Warning,
			title = "Dev realm not supported",
			description = "Discover can only install shared and server realm packages.",
			LayoutOrder = 4,
		}) or nil,

		InstallMessage = props.installError and e(SystemBanner, {
			severity = if props.installStatus == "partial" then AlertSeverity.Warning else AlertSeverity.Error,
			title = if props.installStatus == "partial" then "Installed with warnings" else "Install failed",
			description = props.installError,
			LayoutOrder = 5,
		}) or nil,
	})
end

return PackageActions
