--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local CompactContext = require(StudioDiscover.Source.Common.CompactContext)
local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

local Button = Foundation.Button
local Dropdown = Foundation.Dropdown
local Progress = Foundation.Progress
local Text = Foundation.Text
local View = Foundation.View
local ButtonVariant = Foundation.Enums.ButtonVariant
local InputSize = Foundation.Enums.InputSize
local ProgressShape = Foundation.Enums.ProgressShape
local ProgressSize = Foundation.Enums.ProgressSize

local e = React.createElement

local ACTIONS_WIDTH = 180

type InstallStatus = "idle" | "running" | "success" | "error"

type Props = {
	scope: string,
	name: string,
	authors: { string }?,
	description: string,
	selectedVersion: string,
	versionItems: { Foundation.DropdownItem },
	onVersionChanged: (id: string) -> (),
	installStatus: InstallStatus,
	installMessage: string?,
	isInstallBlocked: boolean,
	onInstall: () -> (),
	LayoutOrder: number?,
}

local function joinAuthors(authors: { string }): string
	if #authors == 0 then
		return "unknown author"
	end
	return table.concat(authors, ", ")
end

local function buttonText(status: InstallStatus): string
	if status == "success" then
		return "Installed"
	elseif status == "error" then
		return "Retry"
	end
	return "Install"
end

local function Hero(props: Props)
	local compact = CompactContext.useCompact()

	local isRunning = props.installStatus == "running"

	local authorText: string
	if props.authors ~= nil and #props.authors > 0 then
		authorText = `by {joinAuthors(props.authors)}`
	else
		authorText = `by {props.scope}`
	end

	local nextTitleOrder = createNextOrder()

	local title = e(Text, {
		tag = "size-full-0 auto-y text-title-large content-emphasis text-align-x-left text-wrap",
		Text = `{props.scope}/{props.name}`,
		LayoutOrder = nextTitleOrder(),
	})

	local author = e(Text, {
		tag = "size-full-0 auto-y text-body-small content-muted text-align-x-left",
		Text = authorText,
		LayoutOrder = nextTitleOrder(),
	})

	local description = e(Text, {
		tag = "size-full-0 auto-y text-body-medium content-default text-align-x-left text-wrap",
		Text = props.description,
		LayoutOrder = nextTitleOrder(),
	})

	-- While running, the Install button slot is replaced by an indeterminate
	-- Progress bar, matching KDE Discover's morph-in-place pattern. Button
	-- returns as "Installed" (disabled) on success or "Retry" on error.
	-- Both fill their container so the hero's Right column (or the compact
	-- stack) stays a consistent width and doesn't spill past the widget edge.
	local installSlot: React.ReactNode
	if isRunning then
		installSlot = e(Progress, {
			shape = ProgressShape.Bar,
			size = ProgressSize.Medium,
			width = UDim.new(1, 0),
		})
	else
		installSlot = e(Button, {
			text = buttonText(props.installStatus),
			variant = ButtonVariant.Emphasis,
			size = InputSize.Medium,
			width = UDim.new(1, 0),
			isDisabled = props.isInstallBlocked or props.installStatus == "success",
			onActivated = props.onInstall,
		})
	end

	local nextActionOrder = createNextOrder()
	local actions = e(View, {
		tag = "size-full-0 auto-y col gap-xsmall",
	}, {
		Dropdown = e(Dropdown.Root, {
			label = "",
			value = props.selectedVersion,
			items = props.versionItems,
			onItemChanged = props.onVersionChanged,
			size = InputSize.Medium,
			width = UDim.new(1, 0),
			maxHeight = 200,
			isDisabled = isRunning,
			LayoutOrder = nextActionOrder(),
		}),
		InstallSlot = e(View, {
			tag = "size-full-0 auto-y row align-y-center",
			LayoutOrder = nextActionOrder(),
		}, {
			Content = installSlot,
		}),
	})

	local statusLine: React.ReactNode = nil
	if props.installMessage ~= nil and props.installMessage ~= "" then
		statusLine = e(Text, {
			tag = "size-full-0 auto-y text-body-small content-muted text-align-x-left text-truncate",
			Text = props.installMessage,
		})
	end

	if compact then
		local nextStackOrder = createNextOrder()
		return e(View, {
			tag = "size-full-0 auto-y col gap-medium padding-large bg-surface-100 radius-medium",
			LayoutOrder = props.LayoutOrder,
		}, {
			Identity = e(View, {
				tag = "size-full-0 auto-y col gap-xsmall",
				LayoutOrder = nextStackOrder(),
			}, {
				TitleText = title,
				Author = author,
				Description = description,
			}),
			Actions = e(View, {
				tag = "size-full-0 auto-y row align-y-center",
				LayoutOrder = nextStackOrder(),
			}, {
				Content = actions,
			}),
			Status = if statusLine ~= nil
				then e(View, {
					tag = "size-full-0 auto-y row",
					LayoutOrder = nextStackOrder(),
				}, {
					Content = statusLine,
				})
				else nil,
		})
	end

	local nextRowOrder = createNextOrder()

	return e(View, {
		tag = "size-full-0 auto-y row align-y-top gap-large padding-large bg-surface-100 radius-medium",
		LayoutOrder = props.LayoutOrder,
	}, {
		Left = e(View, {
			tag = "grow auto-y col gap-xsmall",
			LayoutOrder = nextRowOrder(),
		}, {
			TitleText = title,
			Author = author,
			Description = description,
		}),
		Right = e(View, {
			tag = "auto-y col gap-xsmall",
			Size = UDim2.fromOffset(ACTIONS_WIDTH, 0),
			LayoutOrder = nextRowOrder(),
		}, {
			Actions = actions,
			Status = statusLine,
		}),
	})
end

return Hero
