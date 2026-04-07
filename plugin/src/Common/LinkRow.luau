local StudioService = game:GetService("StudioService")

local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local Button = Foundation.Button

local InputSize = Foundation.Enums.InputSize
local ButtonVariant = Foundation.Enums.ButtonVariant

local e = React.createElement

type LinkRowProps = {
	label: string,
	value: string,
	LayoutOrder: number?,
}

local function LinkRow(props: LinkRowProps)
	return e(Button, {
		text = `{props.label}: {props.value}`,
		variant = ButtonVariant.Link,
		size = InputSize.Small,
		LayoutOrder = props.LayoutOrder,
		onActivated = function()
			pcall(function()
				StudioService:CopyToClipboard(props.value)
			end)
		end,
	})
end

return LinkRow
