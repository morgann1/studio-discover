--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local CompactContext = require(StudioDiscover.Source.Common.CompactContext)
local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

local Button = Foundation.Button
local Dropdown = Foundation.Dropdown
local Text = Foundation.Text
local View = Foundation.View
local ButtonVariant = Foundation.Enums.ButtonVariant
local InputSize = Foundation.Enums.InputSize

local e = React.createElement

local ACTIONS_WIDTH = 220

type Props = {
	scope: string,
	name: string,
	authors: { string }?,
	description: string,
	selectedVersion: string,
	versionItems: { Foundation.DropdownItem },
	onVersionChanged: (id: string) -> (),
	LayoutOrder: number?,
}

local function joinAuthors(authors: { string }): string
	if #authors == 0 then
		return "unknown author"
	end
	return table.concat(authors, ", ")
end

local function Hero(props: Props)
	local compact = CompactContext.useCompact()

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

	local nextActionOrder = createNextOrder()
	local actions = e(View, {
		tag = "size-full-0 auto-y row align-y-center gap-small",
	}, {
		VersionWrap = e(View, {
			tag = "grow auto-y row align-y-center",
			LayoutOrder = nextActionOrder(),
		}, {
			Dropdown = e(Dropdown.Root, {
				label = "",
				value = props.selectedVersion,
				items = props.versionItems,
				onItemChanged = props.onVersionChanged,
				size = InputSize.Medium,
				width = UDim.new(1, 0),
				maxHeight = 200,
			}),
		}),
		Install = e(Button, {
			text = "Install",
			variant = ButtonVariant.Emphasis,
			size = InputSize.Medium,
			isDisabled = true,
			onActivated = function() end,
			LayoutOrder = nextActionOrder(),
		}),
	})

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
			tag = "auto-y col gap-medium",
			Size = UDim2.fromOffset(ACTIONS_WIDTH, 0),
			LayoutOrder = nextRowOrder(),
		}, {
			Actions = actions,
		}),
	})
end

return Hero
