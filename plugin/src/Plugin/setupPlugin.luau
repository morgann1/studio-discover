--!strict

local RunService = game:GetService("RunService")
local StudioService = game:GetService("StudioService")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local DoCleanup = require(StudioDiscover.Packages.DoCleanup)
local Interposer = require(StudioDiscover.Packages.Interposer)
local Leader = require(StudioDiscover.Packages.Leader)
local PluginStore = require(StudioDiscover.Source.Plugin.PluginStore)
local SharedToolbar = require(StudioDiscover.Packages.SharedToolbar)
local buildConfig = require(StudioDiscover.Generated.buildConfig)
local createLogger = require(StudioDiscover.Source.Util.createLogger)

local logger = createLogger.createLogger("plugin.bootstrap")

local WIDGET_INFO = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, 936, 702, 306, 306)

local PROTOCOL_NAMESPACE = "@22:43/shared-toolbar"
local TOOLBAR_ID = "22:43"

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

	local scope: { unknown } = {}

	local interposer = Interposer.logon(buildConfig.mediumName, buildConfig.mediumName, scope)
	local leader = Leader.track(scope, interposer)

	local toolbar = SharedToolbar.connect(
		scope,
		plugin,
		buildConfig.mediumName,
		interposer,
		leader,
		PROTOCOL_NAMESPACE,
		TOOLBAR_ID,
		buildConfig.toolbarTitle,
		buildConfig.peerId,
		{
			[buildConfig.buttonId] = {
				displayName = buildConfig.buttonTitle,
				toolTip = buildConfig.buttonTooltip,
				iconRamp = buildConfig.icon,
				clickableWhenViewportHidden = true,
				creationOrder = 0,
			},
		},
		{}
	)

	table.insert(
		scope,
		toolbar.onClick(function(buttonId: string)
			if buttonId == buildConfig.buttonId then
				widget.Enabled = not widget.Enabled
			end
		end)
	)

	local function setActiveIfLeader(isActive: boolean)
		if leader.selfIsLeader() == true then
			toolbar.setActive(buildConfig.buttonId, isActive)
		end
	end

	local enabledConn = widget:GetPropertyChangedSignal("Enabled"):Connect(function()
		setActiveIfLeader(widget.Enabled)
		if widget.Enabled then
			mount()
		end
	end)

	if widget.Enabled then
		setActiveIfLeader(true)
		mount()
	end

	plugin.Unloading:Connect(function()
		enabledConn:Disconnect()
		DoCleanup(scope)
		if destroyApp ~= nil then
			destroyApp()
			destroyApp = nil
		end
	end)
end

return setupPlugin
