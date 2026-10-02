--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Installer = require(StudioDiscover.Source.Installer)
const MoreMenu = require(StudioDiscover.Source.Common.MoreMenu)
const Navigation = require(StudioDiscover.Source.Navigation)
const SourceLabel = require(StudioDiscover.Source.Common.SourceLabel)
const Table = require(StudioDiscover.Source.Common.Table)
const VersionLabel = require(StudioDiscover.Source.Common.VersionLabel)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const useOperation = require(StudioDiscover.Source.Common.useOperation)

const groupRoots = require(script.Parent.groupRoots)

const Button = Foundation.Button
const Divider = Foundation.Divider
const Text = Foundation.Text
const View = Foundation.View
const ButtonVariant = Foundation.Enums.ButtonVariant
const InputSize = Foundation.Enums.InputSize

const e = React.createElement

const EXPANDED_HEIGHT = 54
const DOCKED_HEIGHT = 60

--[[
	One installed root: its alias, version, and source, with Update when it has an
		update and a "…" menu to remove it otherwise. Activating the row opens its
		package page. A failed action shows under the row.
]]
const function RootRow(props: {
	read entry: groupRoots.Entry,
	read columns: { Table.Column },
	read isDocked: boolean,
	read LayoutOrder: number?,
})
	const root = props.entry.root
	const update = props.entry.update
	const operation = useOperation()
	const isBusy = Installer.useIsBusy()
	const nextOrder = createNextOrder()

	const function open()
		Navigation.pushScreen({
			name = "Package",
			target = { registry = root.registry, scope = root.scope, name = root.name },
		})
	end

	local action: React.Node
	if operation.isRunning then
		action = e(Text, {
			tag = "auto-xy text-body-small content-muted",
			Text = if update ~= nil then "Updating..." else "Removing...",
		})
	elseif update ~= nil then
		action = e(Button, {
			text = "Update",
			size = InputSize.XSmall,
			variant = ButtonVariant.Standard,
			isDisabled = isBusy,
			onActivated = function()
				operation.run(function()
					return Installer.updateAllAsync({ update })
				end)
			end,
		})
	else
		const actions: { MoreMenu.MenuAction } = {
			{ id = "open", text = "Open", onActivated = open },
			{
				id = "remove",
				text = "Remove from this place",
				onActivated = function()
					operation.run(function()
						return Installer.uninstallAsync(root)
					end)
				end,
			},
		}

		action = e(MoreMenu, {
			label = `More for {root.alias}`,
			actions = actions,
		})
	end

	const name = e(Text, {
		tag = {
			["size-full-0 auto-y text-align-x-left text-truncate-end content-emphasis"] = true,
			["text-title-medium"] = props.isDocked,
			["text-body-medium"] = not props.isDocked,
		},
		Text = root.alias,
		LayoutOrder = 1,
	})

	const version = e(VersionLabel, {
		version = root.version,
		latest = if update ~= nil then update.latestVersion else nil,
		LayoutOrder = 1,
	})

	local body: React.Node
	if props.isDocked then
		body = e(View, {
			tag = "size-full-0 row align-y-center gap-small padding-x-medium",
			Size = UDim2.new(1, 0, 0, DOCKED_HEIGHT),
			onActivated = open,
			LayoutOrder = nextOrder(),
		}, {
			Info = e(View, {
				tag = "grow auto-y col gap-xxsmall",
				LayoutOrder = 1,
			}, {
				Name = name,
				Meta = e(View, {
					tag = "size-full-0 auto-y row align-y-center gap-medium",
					LayoutOrder = 2,
				}, {
					Version = version,
					Source = e(SourceLabel, {
						registry = root.registry,
						isMuted = true,
						LayoutOrder = 2,
					}),
				}),
			}),
			Action = e(View, {
				tag = "auto-xy",
				LayoutOrder = 2,
			}, {
				Action = action,
			}),
		})
	else
		const cells: { [string]: React.Node } = {
			name = name,
			version = version,
			source = e(SourceLabel, { registry = root.registry }),
			action = e(View, {
				tag = "size-full row align-x-right align-y-center",
			}, {
				Action = action,
			}),
		}

		body = e(Table.Row, {
			columns = props.columns,
			height = EXPANDED_HEIGHT,
			cells = cells,
			onActivated = open,
			LayoutOrder = nextOrder(),
		})
	end

	return e(View, {
		tag = "size-full-0 auto-y col",
		LayoutOrder = props.LayoutOrder,
	}, {
		Body = body,
		Error = operation.error ~= nil
			and e(Text, {
				tag = "size-full-0 auto-y text-body-small content-alert text-align-x-left text-wrap padding-x-large padding-y-small",
				Text = operation.error,
				LayoutOrder = nextOrder(),
			}),
		Divider = props.isDocked and e(Divider, {
			LayoutOrder = nextOrder(),
		}),
	})
end

return RootRow
