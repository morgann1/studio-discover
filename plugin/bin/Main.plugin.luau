local RunService = game:GetService("RunService")

if RunService:IsRunning() then
	return
end

local Discover = script.Parent.Parent

local studio = settings().Studio

local function isDarkTheme(): boolean
	return studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground).R < 0.5
end

local LIGHT_ICON = "rbxassetid://122071679257586"
local DARK_ICON = "rbxassetid://125842588490194"

local toolbar = plugin:CreateToolbar("Discover")
local button =
	toolbar:CreateButton("Discover", "Browse and install packages", if isDarkTheme() then DARK_ICON else LIGHT_ICON)

local widgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, 405, 492, 280, 320)
local widget = plugin:CreateDockWidgetPluginGuiAsync("DiscoverWidget", widgetInfo)
widget.Title = "Discover"
widget.Name = "Discover"
widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local connections: { RBXScriptConnection } = {}
local reactRoot: any = nil

local function mount()
	if reactRoot then
		return
	end

	local Packages = Discover.Packages
	local React = require(Packages.React)
	local ReactRoblox = require(Packages.ReactRoblox)
	local App = require(Discover.Src.App)

	reactRoot = ReactRoblox.createRoot(widget)
	reactRoot:render(React.createElement(App, { plugin = plugin, overlayGui = widget }))
end

table.insert(
	connections,
	studio.ThemeChanged:Connect(function()
		button.Icon = if isDarkTheme() then DARK_ICON else LIGHT_ICON
	end)
)

table.insert(
	connections,
	button.Click:Connect(function()
		widget.Enabled = not widget.Enabled
	end)
)

table.insert(
	connections,
	widget:GetPropertyChangedSignal("Enabled"):Connect(function()
		button:SetActive(widget.Enabled)
		if widget.Enabled then
			mount()
		end
	end)
)

if widget.Enabled then
	button:SetActive(true)
	mount()
end

plugin.Unloading:Connect(function()
	for _, connection in connections do
		connection:Disconnect()
	end
	table.clear(connections)
	if reactRoot then
		reactRoot:unmount()
	end
end)
