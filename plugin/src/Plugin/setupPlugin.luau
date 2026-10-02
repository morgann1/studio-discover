--!strict

local RunService = game:GetService("RunService")
local StudioService = game:GetService("StudioService")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local PluginStore = require(StudioDiscover.Source.Plugin.PluginStore)
local buildConfig = require(StudioDiscover.Generated.buildConfig)
local createLogger = require(StudioDiscover.Core.createLogger)

local logger = createLogger.createLogger("plugin.bootstrap")

local WIDGET_INFO = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, 936, 702, 306, 306)

local TOOLBAR_NAME = "morganissocoollike"

-- Picks the toolbar icon that contrasts with the ribbon in the current Studio theme.
local function pickToolbarIcon(): string
	local ribbonBackground = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
	local isDark = ribbonBackground.R + ribbonBackground.G + ribbonBackground.B < 1.5

	return if isDark then buildConfig.icons.dark else buildConfig.icons.light
end

local function setupPlugin(plugin: Plugin): ()
	if RunService:IsRunning() then
		return
	end

	if StudioService:GetUserId() == 0 then
		logger.warn("Studio is not signed in (GetUserId == 0); Discover will not initialize")
		return
	end

	plugin.Name = buildConfig.pluginName

	PluginStore.get().setPlugin(plugin)

	local widget = plugin:CreateDockWidgetPluginGuiAsync(buildConfig.widgetId, WIDGET_INFO)
	widget.Title = buildConfig.widgetTitle
	widget.Name = buildConfig.widgetName
	widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local destroyApp: (() -> ())? = nil

	local function mount()
		if destroyApp ~= nil then
			return
		end
		local mountApp = require(StudioDiscover.Source.Plugin.mountApp)
		destroyApp = mountApp(plugin, widget)
	end

	local toolbar = plugin:CreateToolbar(TOOLBAR_NAME)
	local button = toolbar:CreateButton(
		buildConfig.buttonId,
		buildConfig.buttonTooltip,
		pickToolbarIcon(),
		buildConfig.buttonTitle
	)
	button.ClickableWhenViewportHidden = true

	local clickConn = button.Click:Connect(function()
		widget.Enabled = not widget.Enabled
	end)

	local themeConn = settings().Studio.ThemeChanged:Connect(function()
		button.Icon = pickToolbarIcon()
	end)

	local enabledConn = widget:GetPropertyChangedSignal("Enabled"):Connect(function()
		button:SetActive(widget.Enabled)
		if widget.Enabled then
			mount()
		end
	end)

	if widget.Enabled then
		button:SetActive(true)
		mount()
	end

	plugin.Unloading:Connect(function()
		clickConn:Disconnect()
		themeConn:Disconnect()
		enabledConn:Disconnect()
		if destroyApp ~= nil then
			destroyApp()
			destroyApp = nil
		end
	end)
end

return setupPlugin
