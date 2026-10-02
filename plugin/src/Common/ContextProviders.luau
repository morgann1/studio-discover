--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const useThemeName = require(StudioDiscover.Source.Common.useThemeName)

const e = React.createElement

const function ContextProviders(props: {
	read overlayGui: GuiBase2d,
	read children: React.Node,
})
	return e(Foundation.FoundationProvider, {
		theme = useThemeName(),
		overlayGui = props.overlayGui,
	}, props.children)
end

return ContextProviders
