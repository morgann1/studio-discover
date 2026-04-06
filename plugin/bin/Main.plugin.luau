local Discover = script.Parent.Parent
local Packages = Discover.Packages

local React = require(Packages.React)
local ReactRoblox = require(Packages.ReactRoblox)
local Foundation = require(Packages.Foundation)

local App = require(Discover.Src.Components.App)

local e = React.createElement

local toolbar = plugin:CreateToolbar("Discover")
local button = toolbar:CreateButton("Discover", "Browse and install packages", "rbxassetid://6031360355")

local widgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, 405, 492, 405, 492)

local widget = plugin:CreateDockWidgetPluginGuiAsync("DiscoverWidget", widgetInfo)
widget.Title = "Discover"
widget.Name = "Discover"

local root = ReactRoblox.createRoot(Instance.new("Folder"))

root:render(ReactRoblox.createPortal(
	e(Foundation.FoundationProvider, {
		theme = "Dark",
		device = "Desktop",
		plugin = plugin,
		overlayGui = widget,
	}, {
		App = e(App, { plugin = plugin }),
	}),
	widget
))

button.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	button:SetActive(widget.Enabled)
end)

plugin.Unloading:Connect(function()
	root:unmount()
end)
