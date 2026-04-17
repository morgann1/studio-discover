local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local Pill = require(Discover.Src.Common.Pill)
local formatPackageKey = require(Discover.Src.Util.formatPackageKey)

local View = Foundation.View
local Text = Foundation.Text

local e = React.createElement

type PackageHeaderProps = {
	scope: string,
	name: string,
	description: string,
	authors: { string }?,
	authorFallback: string,
	installedVersion: string?,
	LayoutOrder: number?,
}

local function PackageHeader(props: PackageHeaderProps)
	local authors = props.authors
	local authorText = if authors and #authors > 0 then table.concat(authors, ", ") else props.authorFallback

	local authorChildren: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 2),
		}),
	}
	if authors and #authors > 1 then
		authorChildren.Label = e(Text, {
			Text = "Authors:",
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromScale(1, 0),
			tag = "text-caption-small content-muted text-align-x-left",
			LayoutOrder = 0,
		})
		for i, author in authors do
			authorChildren[`author_{i}`] = e(Text, {
				Text = `  {author}`,
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				tag = "text-caption-small content-muted text-align-x-left",
				LayoutOrder = i,
			})
		end
	else
		authorChildren.Label = e(Text, {
			Text = `by {authorText}`,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromScale(1, 0),
			tag = "text-caption-small content-muted text-align-x-left",
			LayoutOrder = 1,
		})
	end

	return e(View, {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = props.LayoutOrder,
		tag = "bg-surface-100 radius-medium",
	}, {
		Padding = e("UIPadding", {
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
			PaddingTop = UDim.new(0, 16),
			PaddingBottom = UDim.new(0, 16),
		}),
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}),
		TitleRow = e("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
			Layout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 8),
			}),
			Title = e(Text, {
				Text = formatPackageKey(props.scope, props.name),
				AutomaticSize = Enum.AutomaticSize.Y,
				Size = UDim2.fromScale(1, 0),
				TextWrapped = true,
				tag = "text-title-medium content-emphasis text-align-x-left",
				LayoutOrder = 1,
			}, {
				Flex = e("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }),
			}),
			InstalledChip = if props.installedVersion
				then e(Pill, {
					text = `Installed v{props.installedVersion}`,
					LayoutOrder = 2,
					emphasis = true,
				})
				else nil,
		}),
		Authors = e("Frame", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 2,
		}, authorChildren),
		Description = e(Text, {
			Text = props.description,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromScale(1, 0),
			TextWrapped = true,
			tag = "text-body-small content-default text-align-x-left text-wrap",
			LayoutOrder = 3,
		}),
	})
end

return PackageHeader
