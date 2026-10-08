--!strict

const RunService = game:GetService("RunService")
const StudioService = game:GetService("StudioService")

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const buildConfig = require(StudioDiscover.Source.buildConfig)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const pluginAtom = require(StudioDiscover.Source.Plugin.pluginAtom)
const requestPermissionsAsync = require(StudioDiscover.Source.Plugin.requestPermissionsAsync)

const logger = createLogger.createLogger("plugin.bootstrap")

const WIDGET_INFO = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, true, 936, 702, 306, 306)

const TOOLBAR_NAME = "morganissocoollike"

-- Picks the toolbar icon that contrasts with the ribbon in the current Studio theme.
const function pickToolbarIcon(): string
	const ribbonBackground = settings().Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
	const isDark = ribbonBackground.R + ribbonBackground.G + ribbonBackground.B < 1.5

	return if isDark then buildConfig.icons.dark else buildConfig.icons.light
end

--[[
	Creates the toolbar button and the dock widget. The app mounts the first time the
		widget opens, so React and the screens only load once someone uses Discover.
]]
const function setupPlugin(plugin: Plugin)
	if RunService:IsRunning() then
		return
	end

	if StudioService:GetUserId() == 0 then
		logger.warn("Studio is not signed in (GetUserId == 0); Discover will not initialize")
		return
	end

	plugin.Name = buildConfig.pluginName
	pluginAtom(plugin)
	task.spawn(requestPermissionsAsync, plugin)

	const widget = plugin:CreateDockWidgetPluginGuiAsync(buildConfig.widgetId, WIDGET_INFO)
	widget.Title = buildConfig.widgetTitle
	widget.Name = buildConfig.widgetName
	widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	local unmountApp: (() -> ())? = nil

	const function mount()
		if unmountApp ~= nil then
			return
		end

		const mountApp = require(StudioDiscover.Source.Plugin.mountApp)
		unmountApp = mountApp(widget)
	end

	const toolbar = plugin:CreateToolbar(TOOLBAR_NAME)
	const button = toolbar:CreateButton(
		buildConfig.buttonId,
		buildConfig.buttonTooltip,
		pickToolbarIcon(),
		buildConfig.buttonTitle
	)
	button.ClickableWhenViewportHidden = true

	const clickConnection = button.Click:Connect(function()
		widget.Enabled = not widget.Enabled
	end)

	const themeConnection = settings().Studio.ThemeChanged:Connect(function()
		button.Icon = pickToolbarIcon()
	end)

	const enabledConnection = widget:GetPropertyChangedSignal("Enabled"):Connect(function()
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
		clickConnection:Disconnect()
		themeConnection:Disconnect()
		enabledConnection:Disconnect()

		if unmountApp ~= nil then
			unmountApp()
			unmountApp = nil
		end
	end)
end

return setupPlugin
