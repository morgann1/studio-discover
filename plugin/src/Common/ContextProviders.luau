--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local useThemeName = require(StudioDiscover.Source.Common.useThemeName)

local e = React.createElement

type Props = {
	overlayGui: GuiBase2d?,
	children: React.ReactNode,
}

local function ContextProviders(props: Props)
	local themeName = useThemeName()

	return e(Foundation.FoundationProvider, {
		theme = themeName,
		overlayGui = props.overlayGui,
	}, props.children)
end

return ContextProviders
