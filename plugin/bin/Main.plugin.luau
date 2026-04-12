local RunService = game:GetService("RunService")

if RunService:IsRunning() then
	return
end

local Discover = script.Parent.Parent
local Packages = Discover.Packages

local React = require(Packages.React)
local ReactRoblox = require(Packages.ReactRoblox)

local App = require(Discover.Src.App)

local e = React.createElement

local studio = settings().Studio

local function isDarkTheme(): boolean
	return studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground).R < 0.5
end

local LIGHT_ICON = "rbxassetid://122071679257586"
local DARK_ICON = "rbxassetid://125842588490194"

local toolbar = plugin:CreateToolbar("Discover")
local button =
	toolbar:CreateButton("Discover", "Browse and install packages", if isDarkTheme() then DARK_ICON else LIGHT_ICON)

studio.ThemeChanged:Connect(function()
	button.Icon = if isDarkTheme() then DARK_ICON else LIGHT_ICON
end)

local widgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, 405, 492, 280, 320)

local widget = plugin:CreateDockWidgetPluginGuiAsync("DiscoverWidget", widgetInfo)
widget.Title = "Discover"
widget.Name = "Discover"
widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local root = ReactRoblox.createRoot(widget)

root:render(e(App, { plugin = plugin, overlayGui = widget }))

button.Click:Connect(function()
	widget.Enabled = not widget.Enabled
end)

widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	button:SetActive(widget.Enabled)
end)

plugin.Unloading:Connect(function()
	root:unmount()
end)
