--!strict

local RunService = game:GetService("RunService")
local StudioService = game:GetService("StudioService")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local PluginStore = require(StudioDiscover.Source.Plugin.PluginStore)
local createLogger = require(StudioDiscover.Source.Util.createLogger)

local logger = createLogger.createLogger("plugin.bootstrap")

local LIGHT_ICON = "rbxassetid://122071679257586"
local DARK_ICON = "rbxassetid://125842588490194"

local studio = settings().Studio

local WIDGET_INFO = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, 936, 702, 306, 306)

local function isDarkTheme(): boolean
	return studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground).R < 0.5
end

local function setupPlugin(plugin: Plugin): ()
	if RunService:IsRunning() then
		return
	end

	-- Wally requires a signed-in Studio session to register API usage against
	-- a real account. Running without one is likely offline Studio or a test
	-- harness; either way the plugin has nothing useful to do.
	if StudioService:GetUserId() == 0 then
		logger.warn("Studio is not signed in (GetUserId == 0); Discover will not initialize")
		return
	end

	plugin.Name = "Discover"

	-- Must run before anything reads from SettingsStore (which resolves the
	-- plugin through PluginStore on first access).
	PluginStore.get().setPlugin(plugin)

	local toolbar = plugin:CreateToolbar("Discover")
	local button =
		toolbar:CreateButton("Discover", "Browse and install packages", if isDarkTheme() then DARK_ICON else LIGHT_ICON)

	local widget = plugin:CreateDockWidgetPluginGuiAsync("DiscoverWidget", WIDGET_INFO)
	widget.Title = "Discover"
	widget.Name = "Discover"
	widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local connections: { RBXScriptConnection } = table.create(3)
	local destroyApp: (() -> ())? = nil

	local function mount()
		if destroyApp ~= nil then
			return
		end
		local mountApp = require(StudioDiscover.Source.Plugin.mountApp)
		destroyApp = mountApp(plugin, widget)
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

		if destroyApp ~= nil then
			destroyApp()
			destroyApp = nil
		end
	end)
end

return setupPlugin
