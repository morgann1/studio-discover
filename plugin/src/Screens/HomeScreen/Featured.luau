--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local Content = require(StudioDiscover.Source.Common.Content)
local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

local PackageCard = require(script.Parent.PackageCard)
local useFeatured = require(script.Parent.useFeatured)

local Loading = Foundation.Loading
local Text = Foundation.Text
local View = Foundation.View

local e = React.createElement

local function Featured()
	local state = useFeatured()

	if state.loading then
		return e(View, {
			tag = "size-full align-x-center align-y-center",
		}, {
			Spinner = e(Loading, {}),
		})
	end

	if #state.packages == 0 then
		return e(View, {
			tag = "size-full align-x-center align-y-center padding-large",
		}, {
			Message = e(Text, {
				tag = "auto-xy text-body-medium content-muted",
				Text = "Couldn't load featured packages.",
			}),
		})
	end

	local nextOrder = createNextOrder()
	local children: { [string]: any } = {}

	children.Heading = e(Text, {
		tag = "size-full-0 auto-y text-title-large content-emphasis text-align-x-left",
		Text = "Featured",
		LayoutOrder = nextOrder(),
	})

	for _, pkg in state.packages do
		children[`{pkg.scope}/{pkg.name}`] = e(PackageCard, {
			registry = "wally",
			scope = pkg.scope,
			name = pkg.name,
			description = pkg.description,
			latestVersion = pkg.latestVersion,
			LayoutOrder = nextOrder(),
		})
	end

	return e(Content, {}, children)
end

return Featured
