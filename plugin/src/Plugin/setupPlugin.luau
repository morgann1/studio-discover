--!strict

local RunService = game:GetService("RunService")
local StudioService = game:GetService("StudioService")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local PluginStore = require(StudioDiscover.Source.Plugin.PluginStore)
local SharedToolbar = require(StudioDiscover.Packages.SharedToolbar)
local createLogger = require(StudioDiscover.Source.Util.createLogger)

local logger = createLogger.createLogger("plugin.bootstrap")

local ICON = "rbxassetid://125842588490194"
local MEDIUM_NAME = "  22:43 Plugin Suite"
local TOOLBAR_TITLE = "22:43"
local BUTTON_ID = "discover"
local PEER_ID = "morgann1/studio-discover"

local WIDGET_INFO = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, 936, 702, 306, 306)

local function setupPlugin(plugin: Plugin): ()
	if RunService:IsRunning() then
		return
	end

	if StudioService:GetUserId() == 0 then
		logger.warn("Studio is not signed in (GetUserId == 0); Discover will not initialize")
		return
	end

	plugin.Name = "Discover"

	PluginStore.get().setPlugin(plugin)

	local widget = plugin:CreateDockWidgetPluginGuiAsync("DiscoverWidget", WIDGET_INFO)
	widget.Title = "Discover"
	widget.Name = "Discover"
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
		mediumName = MEDIUM_NAME,
		toolbarTitle = TOOLBAR_TITLE,
		peerId = PEER_ID,
		buttons = {
			{
				id = BUTTON_ID,
				title = "Discover",
				tooltip = "Browse and install Luau packages",
				iconId = ICON,
				clickableWhenViewportHidden = true,
				onClick = function()
					widget.Enabled = not widget.Enabled
				end,
			},
		},
	})

	local enabledConn = widget:GetPropertyChangedSignal("Enabled"):Connect(function()
		handle:setActive(BUTTON_ID, widget.Enabled)
		if widget.Enabled then
			mount()
		end
	end)

	if widget.Enabled then
		handle:setActive(BUTTON_ID, true)
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
