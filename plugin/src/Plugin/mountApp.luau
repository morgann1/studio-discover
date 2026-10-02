--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const React = require(StudioDiscover.Packages.React)
const ReactRoblox = require(StudioDiscover.Packages.ReactRoblox)

const App = require(StudioDiscover.Source.App)

const e = React.createElement

--[[
	Renders the app into `widget` through a portal from a root it owns, so React never
		clears anything else in the widget. Returns a function that unmounts it.
]]
const function mountApp(widget: DockWidgetPluginGui): () -> ()
	const container = Instance.new("Folder")
	const root = ReactRoblox.createRoot(container)

	root:render(ReactRoblox.createPortal(e(App, { widget = widget }), widget))

	return function()
		root:unmount()
		container:Destroy()
	end
end

return mountApp
