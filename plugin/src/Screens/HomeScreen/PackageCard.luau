--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Navigation = require(StudioDiscover.Source.Navigation)
const RegistryLogo = require(StudioDiscover.Source.Common.RegistryLogo)
const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)
const formatName = require(StudioDiscover.Source.Util.formatName)
const types = require(StudioDiscover.Libraries.Core.types)
const useAtom = require(StudioDiscover.Source.Common.useAtom)

const Text = Foundation.Text
const View = Foundation.View

const e = React.createElement

-- A search or listing result that opens the package screen.
const function PackageCard(props: {
	read registries: { types.Registry },
	read scope: string,
	read name: string,
	read description: string?,
	read latestVersion: string?,
	read LayoutOrder: number?,
})
	const namingConvention = useAtom(function()
		return SettingsStore.getSettings().namingConvention
	end)

	const description = props.description
	const descriptionText = if description ~= nil and string.match(description, "%S") ~= nil
		then description
		else `{formatName(props.name, namingConvention)} has no provided description.`

	const function onView()
		Navigation.pushScreen({
			name = "Package",
			target = {
				registries = props.registries,
				scope = props.scope,
				name = props.name,
			},
		})
	end

	const nextCardOrder = createNextOrder()
	const nextHeadingOrder = createNextOrder()
	const nextBadgeOrder = createNextOrder()

	const badges: { [string]: React.Node } = {}
	for _, registry in props.registries do
		badges[registry] = e(RegistryLogo, {
			registry = registry,
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
			Text = descriptionText,
			LayoutOrder = nextCardOrder(),
		}),
	})
end

return PackageCard
