--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const LayoutContext = require(StudioDiscover.Source.Common.LayoutContext)
const Navigation = require(StudioDiscover.Source.Navigation)
const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const SourceLabel = require(StudioDiscover.Source.Common.SourceLabel)
const Table = require(StudioDiscover.Source.Common.Table)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const createUniqueKey = require(StudioDiscover.Source.Util.createUniqueKey)
const packageDisplayName = require(StudioDiscover.Source.Util.packageDisplayName)
const rowHeights = require(StudioDiscover.Source.Common.rowHeights)
const usePackageStatus = require(StudioDiscover.Source.Common.usePackageStatus)

const ScrollView = Foundation.ScrollView
const StatusBadge = Foundation.StatusBadge
const Text = Foundation.Text
const View = Foundation.View
const StatusBadgeVariant = Foundation.Enums.StatusBadgeVariant

const e = React.createElement

type ColumnSet = {
	read expanded: { Table.Column },
	read docked: { Table.Column },
}

-- A source lists who publishes each package and whether it is installed.
const SOURCE_COLUMNS: ColumnSet = {
	expanded = {
		{ key = "name", label = "Name" },
		{ key = "latest", label = "Latest", width = 112 },
		{ key = "author", label = "Author", width = 160 },
		{ key = "status", label = "Status", width = 112 },
	},
	docked = {
		{ key = "name", label = "Name" },
		{ key = "latest", label = "Latest", width = 96 },
	},
}

--[[
	Search results also say which source each came from. Docked, the author tells
		same-named results apart, and the chips narrow them by source.
]]
const SEARCH_COLUMNS: ColumnSet = {
	expanded = {
		{ key = "name", label = "Name" },
		{ key = "latest", label = "Latest", width = 112 },
		{ key = "source", label = "Source", width = 112 },
		{ key = "author", label = "Author", width = 160 },
	},
	docked = {
		{ key = "name", label = "Name" },
		{ key = "author", label = "Author", width = 112 },
	},
}

const function textCell(text: string, isEmphasized: boolean): React.Node
	return e(Text, {
		tag = {
			["size-full-0 auto-y text-body-medium text-align-x-left text-truncate-end"] = true,
			["content-emphasis"] = isEmphasized,
			["content-default"] = not isEmphasized,
		},
		Text = text,
	})
end

const function statusCell(status: usePackageStatus.PackageStatus?): React.Node
	if status == nil then
		return nil
	end

	return e(StatusBadge, {
		text = if status == "update" then "Update" else "Installed",
		variant = if status == "update" then StatusBadgeVariant.Emphasis else StatusBadgeVariant.Success,
	})
end

--[[
	Packages as a table under a sticky header, each row opening its package page.
		In a narrow widget, only the columns that tell rows apart remain.
]]
const function PackageTable(props: {
	read packages: { coreTypes.PackageBrief },
	read showsSource: boolean,
	read LayoutOrder: number?,
})
	const layout = LayoutContext.useLayout()
	const statusOf = usePackageStatus()
	const settings = SettingsStore.useSettings()

	const columnSets = if props.showsSource then SEARCH_COLUMNS else SOURCE_COLUMNS
	const columns = if layout.isWide then columnSets.expanded else columnSets.docked

	const uniqueKey = createUniqueKey()
	const nextOrder = createNextOrder()
	const nextRowOrder = createNextOrder()
	const rows: { [string]: React.Node } = {}

	for _, brief in props.packages do
		const registry = brief.registries[1]

		const cells: { [string]: React.Node } = {
			name = textCell(packageDisplayName(registry, brief.name, settings), true),
			latest = textCell(brief.latestVersion or "", false),
			author = textCell(brief.scope, false),
			source = e(SourceLabel, { registry = registry }),
			status = statusCell(statusOf(registry, brief.scope, brief.name)),
		}

		rows[uniqueKey(`{registry}:{brief.scope}/{brief.name}`)] = e(Table.Row, {
			columns = columns,
			height = rowHeights.single,
			cells = cells,
			onActivated = function()
				Navigation.pushScreen({
					name = "Package",
					target = { registry = registry, scope = brief.scope, name = brief.name },
				})
			end,
			LayoutOrder = nextRowOrder(),
		})
	end

	return e(View, {
		tag = "size-full col",
		LayoutOrder = props.LayoutOrder,
	}, {
		Header = e(Table.Header, {
			columns = columns,
			LayoutOrder = nextOrder(),
		}),
		Rows = e(ScrollView, {
			tag = "size-full-0 grow",
			scroll = {
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.fromScale(0, 0),
				ScrollingDirection = Enum.ScrollingDirection.Y,
			},
			layout = {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
			},
			LayoutOrder = nextOrder(),
		}, rows),
	})
end

return PackageTable
