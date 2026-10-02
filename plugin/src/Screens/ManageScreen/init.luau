--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Content = require(StudioDiscover.Source.Common.Content)
const Installer = require(StudioDiscover.Source.Installer)
const RootRow = require(StudioDiscover.Source.Common.RootRow)
const Screen = require(StudioDiscover.Source.Common.Screen)
const capitalize = require(StudioDiscover.Source.Util.capitalize)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

const Empty = Foundation.Empty
const Loading = Foundation.Loading
const View = Foundation.View

const e = React.createElement

-- Lists the installed roots for both registries, each with a Remove button.
const function ManageScreen()
	const installedState = Installer.useInstalledRoots()

	local body: React.Node
	if installedState.loading then
		body = e(View, {
			tag = "size-full align-x-center align-y-center",
		}, {
			Spinner = e(Loading, {}),
		})
	elseif #installedState.roots == 0 then
		body = e(View, {
			tag = "size-full align-x-center align-y-center",
		}, {
			EmptyState = e(Empty, {
				text = "No packages installed",
			}),
		})
	else
		const nextOrder = createNextOrder()
		const rows: { [string]: React.Node } = {}

		for _, root in installedState.roots do
			rows[`{root.registry}::{root.realm}::{root.scope}/{root.name}`] = e(RootRow, {
				registry = root.registry,
				scope = root.scope,
				name = root.name,
				meta = `v{root.version} · {capitalize(root.realm)} · {root.alias}`,
				actionText = "Remove",
				isDestructive = true,
				runActionAsync = function()
					return Installer.uninstallAsync(root)
				end,
				LayoutOrder = nextOrder(),
			})
		end

		body = e(Content, {}, rows)
	end

	return e(Screen, { title = "Installed" }, {
		Body = body,
	})
end

return ManageScreen
