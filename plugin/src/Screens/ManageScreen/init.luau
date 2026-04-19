--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local Content = require(StudioDiscover.Source.Common.Content)
local Installer = require(StudioDiscover.Source.Installer)
local Screen = require(StudioDiscover.Source.Common.Screen)
local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

local Row = require(script.Row)

local Empty = Foundation.Empty
local Loading = Foundation.Loading
local View = Foundation.View

local e = React.createElement

local function ManageScreen()
	local installedState = Installer.useInstalledRoots()
	local installedRoots = installedState.roots

	local body: React.ReactNode
	if installedState.loading then
		body = e(View, {
			tag = "size-full align-x-center align-y-center",
		}, {
			Spinner = e(Loading, {}),
		})
	elseif #installedRoots == 0 then
		body = e(View, {
			tag = "size-full align-x-center align-y-center",
		}, {
			EmptyState = e(Empty, {
				text = "No packages installed",
			}),
		})
	else
		local nextOrder = createNextOrder()
		local rows: { [string]: any } = {}
		for _, root in installedRoots do
			local key = `{root.realm}::{root.scope}/{root.name}`
			rows[key] = e(Row, {
				scope = root.scope,
				name = root.name,
				version = root.version,
				alias = root.alias,
				realm = root.realm,
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
