--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local React = require(StudioDiscover.Packages.React)
local ReactRoblox = require(StudioDiscover.Packages.ReactRoblox)

local App = require(StudioDiscover.Source.App)

local e = React.createElement

local function mountApp(plugin: Plugin, widget: DockWidgetPluginGui): () -> ()
	local container = Instance.new("Folder")
	local root = ReactRoblox.createRoot(container)

	root:render(ReactRoblox.createPortal(
		e(App, {
			plugin = plugin,
			overlayGui = widget,
		}),
		widget
	))

	return function()
		root:unmount()
		container:Destroy()
	end
end

return mountApp
