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
	onSelect: (scope: string, name: string, version: string?) -> (),
	LayoutOrder: number,
}

local function parseDepSpec(dependencyVersion: string): (string?, string?, string?)
	-- Mirror wally registry frontend (page.tsx:179):
	-- /(.+\/.+)@[^\d]+([\d.]+)/ — operator(s) then first numeric token.
	local scopeName, version = string.match(dependencyVersion, "(.+/.+)@[^%d]+([%d%.]+)")
	if not scopeName then
		-- Wally's regex requires an operator, so handle bare specs too.
		scopeName, version = string.match(dependencyVersion, "(.+/.+)@([%d%.]+)")
	end
	if not scopeName then
		return nil, nil, nil
	end
	local scope, name = string.match(scopeName, "^(.+)/(.+)$")
	return scope, name, version
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
		local dependencyScope, dependencyName, dependencyVersion = parseDepSpec(tostring(dep.version))
		local displayName
		if dependencyScope and dependencyVersion then
			displayName = `{dependencyScope}/{dependencyName}@{dependencyVersion}`
		elseif dependencyScope then
			displayName = `{dependencyScope}/{dependencyName}`
		else
			displayName = dep.name
		end
		children[depKey(displayName)] = e(Button, {
			text = displayName,
			variant = ButtonVariant.Link,
			size = InputSize.Small,
			LayoutOrder = nextOrder(),
			onActivated = dependencyScope and function()
				props.onSelect(dependencyScope, dependencyName, dependencyVersion)
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
