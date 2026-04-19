--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

local Button = Foundation.Button
local Divider = Foundation.Divider
local Text = Foundation.Text
local View = Foundation.View
local ButtonVariant = Foundation.Enums.ButtonVariant
local InputSize = Foundation.Enums.InputSize

local e = React.createElement

type Props = {
	title: string,
	onBack: (() -> ())?,
	LayoutOrder: number?,
}

-- Mirrors the Sidebar's top section so the header divider aligns horizontally
-- with the sidebar's search/nav divider.
local function Header(props: Props)
	local nextOrder = createNextOrder()

	return e(View, {
		tag = "size-full-0 auto-y bg-surface-100 col gap-small padding-small",
		LayoutOrder = props.LayoutOrder,
		ZIndex = 2,
	}, {
		TitleRow = e(View, {
			tag = "size-full-1000 row align-y-center gap-small padding-left-large",
			LayoutOrder = nextOrder(),
		}, {
			Back = props.onBack ~= nil and e(Button, {
				text = "Back",
				variant = ButtonVariant.Subtle,
				size = InputSize.Small,
				onActivated = props.onBack,
			}),
			Title = e(Text, {
				tag = "auto-y grow text-align-x-left text-title-large content-emphasis",
				Text = props.title,
			}),
		}),

		Divider = e(Divider, {
			LayoutOrder = nextOrder(),
		}),
	})
end

return Header
