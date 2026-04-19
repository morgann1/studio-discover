--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local Content = require(StudioDiscover.Source.Common.Content)
local Installer = require(StudioDiscover.Source.Installer)
local Screen = require(StudioDiscover.Source.Common.Screen)
local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

local Row = require(script.Row)

local Button = Foundation.Button
local Empty = Foundation.Empty
local Loading = Foundation.Loading
local Text = Foundation.Text
local View = Foundation.View
local ButtonVariant = Foundation.Enums.ButtonVariant
local InputSize = Foundation.Enums.InputSize

local e = React.createElement

local function UpdatesScreen()
	local state = Installer.useUpdates()
	local isBusy = Installer.useIsBusy()
	local isUpdatingAll, setIsUpdatingAll = React.useState(false)
	local errorText: string?, setErrorText = React.useState(nil :: string?)
	local mountedRef = React.useRef(true)

	React.useEffect(function()
		return function()
			mountedRef.current = false
		end
	end, {})

	local onUpdateAll = React.useCallback(function()
		if #state.updates == 0 then
			return
		end
		local payload = {}
		for _, entry in state.updates do
			table.insert(payload, {
				scope = entry.scope,
				name = entry.name,
				realm = entry.realm,
				version = entry.latestVersion,
			})
		end
		setIsUpdatingAll(true)
		setErrorText(nil)
		task.spawn(function()
			local result = Installer.updateAllAsync(payload)
			if not mountedRef.current then
				return
			end
			setIsUpdatingAll(false)
			if not result.ok then
				setErrorText(result.error or "Update failed")
			end
		end)
	end, { state.updates } :: { any })

	local body: React.ReactNode
	if state.loading then
		body = e(View, {
			tag = "size-full align-x-center align-y-center",
		}, {
			Spinner = e(Loading, {}),
		})
	elseif #state.updates == 0 then
		body = e(View, {
			tag = "size-full align-x-center align-y-center",
		}, {
			EmptyState = e(Empty, {
				text = "All packages are up to date",
			}),
		})
	else
		local nextOrder = createNextOrder()
		local children: { [string]: any } = {}

		children.Toolbar = e(View, {
			tag = "size-full-0 auto-y row align-y-center gap-medium",
			LayoutOrder = nextOrder(),
		}, {
			Count = e(Text, {
				tag = "grow auto-y text-body-medium content-muted text-align-x-left",
				Text = `{#state.updates} update(s) available`,
			}),
			UpdateAll = e(Button, {
				text = if isUpdatingAll then "Updating…" else "Update All",
				variant = ButtonVariant.Emphasis,
				size = InputSize.Medium,
				isDisabled = isBusy,
				onActivated = onUpdateAll,
			}),
		})

		if errorText ~= nil then
			children.Error = e(Text, {
				tag = "size-full-0 auto-y text-body-small content-alert text-align-x-left text-wrap",
				Text = errorText,
				LayoutOrder = nextOrder(),
			})
		end

		for _, entry in state.updates do
			local key = `{entry.realm}::{entry.scope}/{entry.name}`
			children[key] = e(Row, {
				scope = entry.scope,
				name = entry.name,
				realm = entry.realm,
				installedVersion = entry.installedVersion,
				latestVersion = entry.latestVersion,
				LayoutOrder = nextOrder(),
			})
		end

		body = e(Content, {}, children)
	end

	return e(Screen, { title = "Updates" }, {
		Body = body,
	})
end

return UpdatesScreen
