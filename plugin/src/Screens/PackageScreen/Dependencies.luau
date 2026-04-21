--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local Navigation = require(StudioDiscover.Source.Navigation)
local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
local createUniqueKey = require(StudioDiscover.Source.Util.createUniqueKey)
local types = require(StudioDiscover.Source.Api.types)

local Button = Foundation.Button
local View = Foundation.View
local ButtonVariant = Foundation.Enums.ButtonVariant
local InputSize = Foundation.Enums.InputSize

local e = React.createElement

type Props = {
	deps: types.WallyDependencyMap,
	registry: types.Registry,
	LayoutOrder: number?,
}

local function parseDepSpec(spec: string): (string?, string?, string?)
	local scopeName, version = string.match(spec, "(.+/.+)@[^%d]+([%d%.]+)")
	if scopeName == nil then
		scopeName, version = string.match(spec, "(.+/.+)@([%d%.]+)")
	end
	if scopeName == nil then
		return nil, nil, nil
	end
	local scope, name = string.match(scopeName, "^(.+)/(.+)$")
	return scope, name, version
end

local function Dependencies(props: Props)
	local uniqueKey = createUniqueKey()
	local nextOrder = createNextOrder()

	local children: { [string]: any } = {}

	for _, spec in props.deps do
		local scope, name, version = parseDepSpec(spec)

		local label: string
		local onActivated: () -> ()
		if scope ~= nil and name ~= nil then
			label = if version ~= nil then `{scope}/{name}@{version}` else `{scope}/{name}`
			onActivated = function()
				Navigation.pushScreen("Package", {
					scope = scope,
					name = name,
					version = version,
					registry = props.registry,
				})
			end
		else
			label = spec
			onActivated = function() end
		end

		children[uniqueKey(label)] = e(Button, {
			text = label,
			variant = ButtonVariant.Link,
			size = InputSize.Small,
			isDisabled = scope == nil,
			onActivated = onActivated,
			LayoutOrder = nextOrder(),
		})
	end

	return e(View, {
		tag = "size-full-0 auto-y col align-x-left",
		LayoutOrder = props.LayoutOrder,
	}, children)
end

return Dependencies
