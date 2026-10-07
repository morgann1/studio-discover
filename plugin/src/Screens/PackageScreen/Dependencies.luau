--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Navigation = require(StudioDiscover.Source.Navigation)
const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const createUniqueKey = require(StudioDiscover.Source.Util.createUniqueKey)
const packageDisplayName = require(StudioDiscover.Source.Util.packageDisplayName)
const rowHeights = require(StudioDiscover.Source.Common.rowHeights)

const parseDependency = require(script.Parent.parseDependency)

const Divider = Foundation.Divider
const Icon = Foundation.Icon
const Text = Foundation.Text
const View = Foundation.View
const IconName = Foundation.Enums.IconName
const IconSize = Foundation.Enums.IconSize

const e = React.createElement

--[[
	Each dependency's name, with its scope and range under it, opening the
		dependency's page. A spec that doesn't parse shows as written, inert.
]]
const function Dependencies(props: {
	read specs: { string },
	read registry: coreTypes.Registry,
	read LayoutOrder: number?,
})
	const settings = SettingsStore.useSettings()

	const uniqueKey = createUniqueKey()
	const nextOrder = createNextOrder()
	const rows: { [string]: React.Node } = {}

	for _, spec in props.specs do
		const dependency = parseDependency(spec)
		const nextRowOrder = createNextOrder()

		const open = if dependency ~= nil
			then function()
				Navigation.pushScreen({
					name = "Package",
					target = {
						registry = props.registry,
						scope = dependency.scope,
						name = dependency.name,
						version = dependency.version,
					},
				})
			end
			else nil

		rows[uniqueKey(spec)] = e(View, {
			tag = "size-full-0 auto-y col",
			LayoutOrder = nextOrder(),
		}, {
			Body = e(View, {
				tag = "size-full-0 row align-y-center gap-medium",
				Size = UDim2.new(1, 0, 0, rowHeights.double),
				onActivated = open,
				LayoutOrder = nextRowOrder(),
			}, {
				Text = e(View, {
					tag = "grow auto-y col gap-xxsmall",
					LayoutOrder = 1,
				}, {
					Name = e(Text, {
						tag = {
							["size-full-0 auto-y text-body-medium text-align-x-left text-truncate-end"] = true,
							["content-emphasis"] = dependency ~= nil,
							["content-default"] = dependency == nil,
						},
						Text = if dependency ~= nil
							then packageDisplayName(props.registry, dependency.name, settings)
							else spec,
						LayoutOrder = 1,
					}),
					Detail = dependency ~= nil
						and e(Text, {
							tag = "size-full-0 auto-y text-body-small content-muted text-align-x-left text-truncate-end",
							Text = `{dependency.scope} · {dependency.range}`,
							LayoutOrder = 2,
						}),
				}),
				Chevron = dependency ~= nil and e(Icon, {
					name = IconName.ChevronSmallRight,
					size = IconSize.Small,
					LayoutOrder = 2,
				}),
			}),
			Divider = e(Divider, {
				LayoutOrder = nextRowOrder(),
			}),
		})
	end

	return e(View, {
		tag = "size-full-0 auto-y col",
		LayoutOrder = props.LayoutOrder,
	}, rows)
end

return Dependencies
