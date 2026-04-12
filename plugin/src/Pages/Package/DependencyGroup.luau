local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Foundation = require(Packages.Foundation)
local React = require(Packages.React)

local ReactHelpers = require(Discover.Src.Common.React)

local Button = Foundation.Button
local Text = Foundation.Text

local InputSize = Foundation.Enums.InputSize
local ButtonVariant = Foundation.Enums.ButtonVariant

local e = React.createElement

export type Dependency = {
	name: string,
	version: string,
	category: string,
}

type DependencyGroupProps = {
	label: string?,
	deps: { Dependency },
	onSelect: (scope: string, name: string) -> (),
	LayoutOrder: number,
}

local function parseDepPath(dependencyVersion: string): (string?, string?)
	local path = string.match(dependencyVersion, "^([^@]+)")
	if path then
		local s, n = string.match(path, "^(.+)/(.+)$")
		return s, n
	end
	return nil, nil
end

local function DependencyGroup(props: DependencyGroupProps)
	local depKey = ReactHelpers.createUniqueKey()
	local nextOrder = ReactHelpers.createNextOrder()

	local children: { [string]: any } = {
		Layout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 4),
		}),
	}

	if props.label then
		children.Header = e(Text, {
			Text = `{props.label} ({#props.deps})`,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromScale(1, 0),
			tag = "text-caption-small content-muted text-align-x-left",
			LayoutOrder = nextOrder(),
		})
	end

	for _, dep in props.deps do
		local dependencyScope, dependencyName = parseDepPath(tostring(dep.version))
		local displayName = dependencyScope and `{dependencyScope}/{dependencyName}` or dep.name
		children[depKey(displayName)] = e(Button, {
			text = displayName,
			variant = ButtonVariant.Link,
			size = InputSize.Small,
			LayoutOrder = nextOrder(),
			onActivated = dependencyScope and function()
				props.onSelect(dependencyScope, dependencyName)
			end or nil,
		})
	end

	return e("Frame", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
	}, children)
end

return DependencyGroup
