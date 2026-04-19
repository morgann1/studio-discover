--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local Installer = require(StudioDiscover.Source.Installer)
local Navigation = require(StudioDiscover.Source.Navigation)
local capitalize = require(StudioDiscover.Source.Util.capitalize)
local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

local Button = Foundation.Button
local Progress = Foundation.Progress
local Text = Foundation.Text
local View = Foundation.View
local ButtonVariant = Foundation.Enums.ButtonVariant
local InputSize = Foundation.Enums.InputSize
local ProgressShape = Foundation.Enums.ProgressShape
local ProgressSize = Foundation.Enums.ProgressSize

local e = React.createElement

type Realm = "shared" | "server"

type Props = {
	scope: string,
	name: string,
	version: string,
	alias: string,
	realm: Realm,
	LayoutOrder: number?,
}

local function Row(props: Props)
	local isRemoving, setIsRemoving = React.useState(false)
	local errorText: string?, setErrorText = React.useState(nil :: string?)
	local isBusy = Installer.useIsBusy()
	local mountedRef = React.useRef(true)

	React.useEffect(function()
		return function()
			mountedRef.current = false
		end
	end, {})

	local onView = React.useCallback(function()
		Navigation.pushScreen("Package", {
			scope = props.scope,
			name = props.name,
		})
	end, { props.scope, props.name } :: { any })

	local onRemove = React.useCallback(function()
		setIsRemoving(true)
		setErrorText(nil)
		task.spawn(function()
			local result = Installer.uninstallAsync(props.scope, props.name, props.realm)
			if not mountedRef.current then
				return
			end
			if not result.ok then
				setErrorText(result.error or "Uninstall failed")
				setIsRemoving(false)
			end
		end)
	end, { props.scope, props.name, props.realm } :: { any })

	local nextOrder = createNextOrder()

	local actionSlot: React.ReactNode
	if isRemoving then
		actionSlot = e(Progress, {
			shape = ProgressShape.Bar,
			size = ProgressSize.Small,
			width = UDim.new(0, 120),
			LayoutOrder = nextOrder(),
		})
	else
		actionSlot = e(Button, {
			text = "Remove",
			variant = ButtonVariant.Alert,
			size = InputSize.Small,
			isDisabled = isBusy,
			onActivated = onRemove,
			LayoutOrder = nextOrder(),
		})
	end

	local nextRootOrder = createNextOrder()

	return e(View, {
		tag = "size-full-0 auto-y col gap-xsmall",
		LayoutOrder = props.LayoutOrder,
	}, {
		Card = e(View, {
			tag = "size-full-0 auto-y row align-y-center gap-medium padding-medium bg-surface-200 radius-medium",
			onActivated = onView,
			LayoutOrder = nextRootOrder(),
		}, {
			Info = e(View, {
				tag = "grow auto-y col gap-xsmall",
				LayoutOrder = nextOrder(),
			}, {
				Title = e(Text, {
					tag = "size-full-0 auto-y text-title-small content-emphasis text-align-x-left text-wrap",
					Text = `{props.scope}/{props.name}`,
				}),
				Meta = e(Text, {
					tag = "size-full-0 auto-y text-body-small content-muted text-align-x-left",
					Text = `v{props.version} · {capitalize(props.realm)} · {props.alias}`,
				}),
			}),
			Action = actionSlot,
		}),
		Error = if errorText ~= nil
			then e(Text, {
				tag = "size-full-0 auto-y text-body-small content-alert text-align-x-left text-wrap",
				Text = errorText,
				LayoutOrder = nextRootOrder(),
			})
			else nil,
	})
end

return Row
