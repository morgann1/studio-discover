local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)
local StudioComponents = require(Packages.StudioComponents)

local Navigation = require(Discover.Src.UI.Navigation)

local e = React.createElement

type StubPageProps = {
	title: string,
}

local function StubPage(props: StubPageProps)
	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 12),
		}),
		Title = e(StudioComponents.Label, {
			Text = props.title,
			Size = UDim2.fromOffset(160, 20),
			TextXAlignment = Enum.TextXAlignment.Center,
			LayoutOrder = 1,
		}),
		Back = e(StudioComponents.Button, {
			Text = "Back",
			Size = UDim2.fromOffset(160, 24),
			LayoutOrder = 2,
			OnActivated = Navigation.pop,
		}),
	})
end

return StubPage
