--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Navigation = require(StudioDiscover.Source.Navigation)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const createUniqueKey = require(StudioDiscover.Source.Util.createUniqueKey)

const Button = Foundation.Button
const View = Foundation.View
const ButtonVariant = Foundation.Enums.ButtonVariant
const InputSize = Foundation.Enums.InputSize

const e = React.createElement

-- Splits "scope/name@constraint" into its parts, with the constraint's version number.
const function parseDependency(spec: string): (string?, string?, string?)
	local scopeName, version = string.match(spec, "(.+/.+)@[^%d]+([%d%.]+)")
	if scopeName == nil then
		scopeName, version = string.match(spec, "(.+/.+)@([%d%.]+)")
	end

	if scopeName == nil then
		return nil, nil, nil
	end

	const scope, name = string.match(scopeName, "^(.+)/(.+)$")
	return scope, name, version
end

-- Links to each dependency's package screen. A spec that does not parse shows as disabled text.
const function Dependencies(props: {
	read dependencies: coreTypes.DependencyMap,
	read registry: coreTypes.Registry,
	read LayoutOrder: number?,
})
	const uniqueKey = createUniqueKey()
	const nextOrder = createNextOrder()
	const children: { [string]: React.Node } = {}

	for _, spec in props.dependencies do
		const scope, name, version = parseDependency(spec)
		local label = spec
		local onActivated: (() -> ())? = nil

		if scope ~= nil and name ~= nil then
			label = if version ~= nil then `{scope}/{name}@{version}` else `{scope}/{name}`
			onActivated = function()
				Navigation.pushScreen({
					name = "Package",
					target = {
						registries = { props.registry },
						scope = scope,
						name = name,
						version = version,
					},
				})
			end
		end

		children[uniqueKey(label)] = e(Button, {
			text = label,
			variant = ButtonVariant.Link,
			size = InputSize.Small,
			isDisabled = onActivated == nil,
			onActivated = onActivated or function() end,
			LayoutOrder = nextOrder(),
		})
	end

	return e(View, {
		tag = "size-full-0 auto-y col align-x-left",
		LayoutOrder = props.LayoutOrder,
	}, children)
end

return Dependencies
