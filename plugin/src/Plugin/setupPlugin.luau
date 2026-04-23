--!strict

local RunService = game:GetService("RunService")
local StudioService = game:GetService("StudioService")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local PluginStore = require(StudioDiscover.Source.Plugin.PluginStore)
local SharedToolbar = require(StudioDiscover.Packages.SharedToolbar)
local buildConfig = require(StudioDiscover.Generated.buildConfig)
local createLogger = require(StudioDiscover.Source.Util.createLogger)

local logger = createLogger.createLogger("plugin.bootstrap")

local WIDGET_INFO = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, 936, 702, 306, 306)

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

	local handle = SharedToolbar.register({
		plugin = plugin,
		mediumName = buildConfig.mediumName,
		toolbarTitle = buildConfig.toolbarTitle,
		peerId = buildConfig.peerId,
		buttons = {
			{
				id = buildConfig.buttonId,
				title = buildConfig.buttonTitle,
				tooltip = buildConfig.buttonTooltip,
				iconId = buildConfig.icon,
				clickableWhenViewportHidden = true,
				onClick = function()
					widget.Enabled = not widget.Enabled
				end,
			},
		},
	})

	local enabledConn = widget:GetPropertyChangedSignal("Enabled"):Connect(function()
		handle:setActive(buildConfig.buttonId, widget.Enabled)
		if widget.Enabled then
			mount()
		end
	end)

	if widget.Enabled then
		handle:setActive(buildConfig.buttonId, true)
		mount()
	end

	plugin.Unloading:Connect(function()
		enabledConn:Disconnect()
		handle:destroy()
		if destroyApp ~= nil then
			destroyApp()
			destroyApp = nil
		end
	end)
end

return setupPlugin
