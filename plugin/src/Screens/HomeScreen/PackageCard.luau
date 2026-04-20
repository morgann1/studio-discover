--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)
local ReactCharm = require(StudioDiscover.Packages.ReactCharm)

local types = require(StudioDiscover.Source.Api.types)

local Navigation = require(StudioDiscover.Source.Navigation)
local SettingsStore = require(StudioDiscover.Source.SettingsStore)
local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
local formatName = require(StudioDiscover.Source.Util.formatName)

local Image = Foundation.Image
local Text = Foundation.Text
local View = Foundation.View

local e = React.createElement

type Registry = types.Registry

type Props = {
	registries: { Registry },
	scope: string,
	name: string,
	description: string?,
	latestVersion: string?,
	LayoutOrder: number?,
}

local REGISTRY_LOGOS: { [Registry]: string } = {
	wally = "rbxassetid://87427394631506",
	pesde = "rbxassetid://125159874176259",
}

local function PackageCard(props: Props)
	local namingConvention = ReactCharm.useAtom(function()
		return SettingsStore.get().getStorage().namingConvention
	end)

	local displayName = formatName(props.name, namingConvention)
	local hasDescription = props.description ~= nil and props.description:match("%S") ~= nil
	local description: string = if hasDescription
		then props.description :: string
		else `{displayName} has no provided description.`

	local onView = function()
		Navigation.pushScreen("Package", {
			registries = props.registries,
			scope = props.scope,
			name = props.name,
		})
	end

	local nextCardOrder = createNextOrder()
	local nextHeadingOrder = createNextOrder()
	local nextBadgeOrder = createNextOrder()

	local badges: { [string]: any } = {}
	for _, registry: Registry in props.registries do
		badges[registry] = e(Image, {
			Image = REGISTRY_LOGOS[registry],
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromOffset(56, 22),
			LayoutOrder = nextBadgeOrder(),
		})
	end

	return e(View, {
		tag = "size-full-0 auto-y col gap-small padding-medium bg-surface-200 radius-medium",
		onActivated = onView,
		LayoutOrder = props.LayoutOrder,
	}, {
		Heading = e(View, {
			tag = "size-full-0 auto-y row align-y-center gap-small",
			LayoutOrder = nextCardOrder(),
		}, {
			Title = e(Text, {
				tag = "grow auto-y text-title-medium content-emphasis text-align-x-left text-wrap",
				Text = `{props.scope}/{props.name}`,
				LayoutOrder = nextHeadingOrder(),
			}),
			Version = props.latestVersion ~= nil and e(Text, {
				tag = "auto-xy text-body-small content-muted",
				Text = `v{props.latestVersion}`,
				LayoutOrder = nextHeadingOrder(),
			}),
			Badges = e(View, {
				tag = "auto-xy row align-y-center gap-xsmall",
				LayoutOrder = nextHeadingOrder(),
			}, badges),
		}),
		Description = e(Text, {
			tag = "size-full-0 auto-y text-body-medium content-muted text-align-x-left text-wrap",
			Text = description,
			LayoutOrder = nextCardOrder(),
		}),
	})
end

return PackageCard
