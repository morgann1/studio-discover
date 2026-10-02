--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

const Button = Foundation.Button
const Divider = Foundation.Divider
const Text = Foundation.Text
const View = Foundation.View
const ButtonVariant = Foundation.Enums.ButtonVariant
const IconName = Foundation.Enums.IconName
const InputSize = Foundation.Enums.InputSize

const e = React.createElement

const function Header(props: {
	read title: string,
	read onBack: (() -> ())?,
	read LayoutOrder: number?,
})
	const nextOrder = createNextOrder()

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
				icon = IconName.ChevronLargeLeft,
				variant = ButtonVariant.Utility,
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
