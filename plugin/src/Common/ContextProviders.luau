--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const useAtom = require(StudioDiscover.Source.Common.useAtom)
const useThemeName = require(StudioDiscover.Source.Common.useThemeName)

const e = React.createElement

-- Foundation, in Studio's theme, with its animations off when the user reduces motion.
const function ContextProviders(props: {
	read overlayGui: GuiBase2d,
	read children: React.Node,
})
	const reduceMotion = useAtom(function()
		return SettingsStore.getSettings().reduceMotion
	end)

	const preferences = React.useMemo(function()
		return { reducedMotion = reduceMotion }
	end, { reduceMotion } :: { unknown })

	return e(Foundation.FoundationProvider, {
		colorMode = useThemeName(),
		overlayGui = props.overlayGui,
		preferences = preferences,
	}, props.children)
end

return ContextProviders
