local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)
local StudioComponents = require(Packages.StudioComponents)

local Navigation = require(Discover.Src.UI.Navigation)

local e = React.createElement

local function Home()
	return e("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
	}, {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 8),
		}),
		OpenPackage = e(StudioComponents.Button, {
			Text = "Open a package (test drill-down)",
			Size = UDim2.fromOffset(240, 24),
			LayoutOrder = 1,
			OnActivated = function()
				Navigation.push("Package")
			end,
		}),
	})
end

return Home
