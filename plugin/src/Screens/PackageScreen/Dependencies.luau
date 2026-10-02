--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Navigation = require(StudioDiscover.Source.Navigation)
const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const createUniqueKey = require(StudioDiscover.Source.Util.createUniqueKey)
const formatName = require(StudioDiscover.Source.Util.formatName)
const useAtom = require(StudioDiscover.Source.Common.useAtom)

const parseDependency = require(script.Parent.parseDependency)

const Divider = Foundation.Divider
const Icon = Foundation.Icon
const Link = Foundation.Link
const Text = Foundation.Text
const View = Foundation.View
const IconName = Foundation.Enums.IconName
const IconSize = Foundation.Enums.IconSize
const InputSize = Foundation.Enums.InputSize

const e = React.createElement

const ROW_HEIGHT = 56

--[[
	Each dependency's name, with its scope and range under it, opening the
		dependency's page. A spec that doesn't parse shows as written, inert.
]]
const function Dependencies(props: {
	read specs: { string },
	read registry: coreTypes.Registry,
	read LayoutOrder: number?,
})
	const namingConvention = useAtom(function()
		return SettingsStore.getSettings().namingConvention
	end)

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
				Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
				onActivated = open,
				LayoutOrder = nextRowOrder(),
			}, {
				Text = e(View, {
					tag = "grow auto-y col gap-xxsmall",
					LayoutOrder = 1,
				}, {
					Name = if dependency ~= nil and open ~= nil
						then e(Link, {
							text = formatName(dependency.name, namingConvention),
							size = InputSize.Medium,
							onActivated = open,
							LayoutOrder = 1,
						})
						else e(Text, {
							tag = "size-full-0 auto-y text-body-medium content-default text-align-x-left text-truncate-end",
							Text = spec,
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
