--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Installer = require(StudioDiscover.Source.Installer)
const EmptyState = require(StudioDiscover.Source.Common.EmptyState)
const LayoutContext = require(StudioDiscover.Source.Common.LayoutContext)
const Message = require(StudioDiscover.Source.Common.Message)
const Navigation = require(StudioDiscover.Source.Navigation)
const Screen = require(StudioDiscover.Source.Common.Screen)
const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const Table = require(StudioDiscover.Source.Common.Table)
const capitalize = require(StudioDiscover.Source.Util.capitalize)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const iconName = require(StudioDiscover.Source.Util.iconName)
const isRegistryEnabled = require(StudioDiscover.Source.Util.isRegistryEnabled)
const packagesPath = require(StudioDiscover.Source.Util.packagesPath)
const plural = require(StudioDiscover.Source.Util.plural)
const registries = require(StudioDiscover.Libraries.Core.registries)
const registryLabel = require(StudioDiscover.Source.Util.registryLabel)

const RootRow = require(script.RootRow)
const UpdatesAlert = require(script.UpdatesAlert)
const groupRoots = require(script.groupRoots)

const ScrollView = Foundation.ScrollView
const Text = Foundation.Text
const View = Foundation.View

const e = React.createElement

const COLUMNS: { Table.Column } = {
	{ key = "name", label = "Name" },
	{ key = "version", label = "Version", width = 168 },
	{ key = "source", label = "Source", width = 128 },
	{ key = "action", label = "", width = 104 },
}

--[[
	A realm's heading, with the folders its rows live in, such as
		"ReplicatedStorage.Packages". Docked, or with more than one folder, the
		folders go under the realm, one per line.
]]
const function groupHeading(group: groupRoots.Group, isDocked: boolean, layoutOrder: number): React.Node
	const paths: { string } = {}
	for _, registry in registries do
		for _, entry in group.entries do
			if entry.root.registry == registry then
				table.insert(paths, packagesPath(registry, group.realm))
				break
			end
		end
	end

	const isStacked = isDocked or #paths > 1

	return e(View, {
		tag = {
			["size-full-0 auto-y padding-x-large padding-top-large padding-bottom-small"] = true,
			["col gap-xxsmall"] = isStacked,
			["row align-y-center gap-medium"] = not isStacked,
		},
		LayoutOrder = layoutOrder,
	}, {
		Realm = e(Text, {
			tag = "auto-xy text-title-medium content-emphasis",
			Text = capitalize(group.realm),
			LayoutOrder = 1,
		}),
		Path = e(Text, {
			tag = {
				["text-body-small content-muted text-align-x-left"] = true,
				["size-full-0 auto-y text-wrap"] = isStacked,
				["auto-xy"] = not isStacked,
			},
			Text = table.concat(paths, "\n"),
			LayoutOrder = 2,
		}),
	})
end

--[[
	What's installed in this place, grouped by realm, under an alert offering every
		waiting update. With `onlyUpdates`, it lists only the roots with an update,
		which is the Updates location.
]]
const function InstalledScreen(props: {
	read onlyUpdates: boolean,
})
	const layout = LayoutContext.useLayout()
	const installed = Installer.useInstalledRoots()
	const updates = Installer.useUpdates()
	const settings = SettingsStore.useSettings()
	const enabled = settings.registries
	const query, setQuery = React.useState("")

	-- How tall the alert and column labels above the rows are, so the rows can fill the rest.
	const topHeight, setTopHeight = React.useBinding(0)
	const onTopSizeChanged = React.useCallback(function(top: GuiObject)
		setTopHeight(top.AbsoluteSize.Y)
	end, {})

	-- The search row only shows docked, so a wider widget drops the filter along with it.
	const activeQuery = if layout.isDocked then query else ""
	const groups = groupRoots(installed.roots, updates.updates, activeQuery, props.onlyUpdates, settings)

	local firstSource = nil
	for _, registry in registries do
		if isRegistryEnabled(enabled, registry) then
			firstSource = registry
			break
		end
	end

	local body: React.Node
	if installed.loading then
		body = e(Message, { text = "Reading this place..." })
	elseif #installed.roots == 0 then
		body = e(EmptyState, {
			icon = iconName("FileBox"),
			text = "Nothing is installed in this place yet.",
			action = if firstSource ~= nil
				then {
					text = `Browse {registryLabel(firstSource)}`,
					icon = iconName("MagnifyingGlass"),
					onActivated = function()
						Navigation.resetScreen({ name = "Source", registry = firstSource })
					end,
				}
				else nil,
		})
	elseif #groups == 0 and activeQuery ~= "" then
		body = e(Message, { text = `Nothing installed matches "{activeQuery}".` })
	elseif #groups == 0 and updates.loading then
		body = e(Message, { text = "Checking for updates..." })
	elseif #groups == 0 and updates.failed > 0 then
		body = e(Message, {
			text = `Couldn't check {plural(updates.failed, "package")} for updates.`,
			action = { text = "Try again", onActivated = Installer.refreshInstalledRoots },
		})
	elseif #groups == 0 then
		body = e(EmptyState, {
			icon = iconName("CircleCheck"),
			text = "Everything is up to date.",
		})
	else
		const nextOrder = createNextOrder()
		const nextRowOrder = createNextOrder()
		const rows: { [string]: React.Node } = {}

		for _, group in groups do
			rows[group.realm] = groupHeading(group, not layout.isWide, nextRowOrder())

			for _, entry in group.entries do
				const root = entry.root

				rows[`{root.registry}:{root.realm}:{root.scope}/{root.name}`] = e(RootRow, {
					entry = entry,
					columns = COLUMNS,
					isDocked = not layout.isWide,
					LayoutOrder = nextRowOrder(),
				})
			end
		end

		--[[
			The rows fill the height the alert and column labels leave, rather than
				growing as a flex item. A `grow` sibling makes Roblox measure the alert's
				wrapped text as one line, which clips it when the widget is docked.
		]]
		body = e(View, {
			tag = "size-full",
		}, {
			Top = e(View, {
				tag = "size-full-0 auto-y col",
				onAbsoluteSizeChanged = onTopSizeChanged,
			}, {
				Alert = e(UpdatesAlert, {
					updates = updates.updates,
					failed = updates.failed,
					isChecking = updates.loading,
					LayoutOrder = nextOrder(),
				}),
				Header = layout.isWide and e(Table.Header, {
					columns = COLUMNS,
					LayoutOrder = nextOrder(),
				}),
			}),
			Rows = e(ScrollView, {
				Size = topHeight:map(function(height: number)
					return UDim2.new(1, 0, 1, -height)
				end),
				Position = topHeight:map(function(height: number)
					return UDim2.fromOffset(0, height)
				end),
				scroll = {
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					CanvasSize = UDim2.fromScale(0, 0),
					ScrollingDirection = Enum.ScrollingDirection.Y,
				},
				layout = {
					FillDirection = Enum.FillDirection.Vertical,
					SortOrder = Enum.SortOrder.LayoutOrder,
				},
			}, rows),
		})
	end

	return e(Screen, {
		search = {
			text = query,
			placeholder = "Search this place",
			onChanged = setQuery,
		},
	}, {
		Body = body,
	})
end

return InstalledScreen
