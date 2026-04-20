--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local Installer = require(StudioDiscover.Source.Installer)
local Navigation = require(StudioDiscover.Source.Navigation)
local RegistryLogo = require(StudioDiscover.Source.Common.RegistryLogo)
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
type Registry = "wally" | "pesde"

type Props = {
	scope: string,
	name: string,
	version: string,
	alias: string,
	realm: Realm,
	registry: Registry,
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
			registry = props.registry,
		})
	end, { props.scope, props.name, props.registry } :: { any })

	local onRemove = React.useCallback(function()
		setIsRemoving(true)
		setErrorText(nil)
		task.spawn(function()
			local result = Installer.uninstallAsync(props.scope, props.name, props.realm, props.registry)
			if not mountedRef.current then
				return
			end
			if not result.ok then
				setErrorText(result.error or "Uninstall failed")
				setIsRemoving(false)
			end
		end)
	end, { props.scope, props.name, props.realm, props.registry } :: { any })

	local nextOrder = createNextOrder()

	local actionSlot: React.ReactNode
	if isRemoving then
		actionSlot = e(Progress, {
			shape = ProgressShape.Bar,
			size = ProgressSize.Small,
			width = UDim.new(0, 96),
		})
	else
		actionSlot = e(Button, {
			text = "Remove",
			variant = ButtonVariant.Alert,
			size = InputSize.Small,
			isDisabled = isBusy,
			onActivated = onRemove,
		})
	end

	local nextInfoOrder = createNextOrder()
	local nextSideOrder = createNextOrder()
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
					tag = "size-full-0 auto-y text-title-medium content-emphasis text-align-x-left text-wrap",
					Text = `{props.scope}/{props.name}`,
					LayoutOrder = nextInfoOrder(),
				}),
				Meta = e(Text, {
					tag = "size-full-0 auto-y text-body-small content-muted text-align-x-left",
					Text = `v{props.version} · {capitalize(props.realm)} · {props.alias}`,
					LayoutOrder = nextInfoOrder(),
				}),
			}),
			Side = e(View, {
				tag = "auto-xy row align-y-center gap-small",
				LayoutOrder = nextOrder(),
			}, {
				Registry = e(RegistryLogo, {
					registry = props.registry,
					LayoutOrder = nextSideOrder(),
				}),
				Action = e(View, {
					tag = "auto-xy row align-y-center",
					LayoutOrder = nextSideOrder(),
				}, {
					Slot = actionSlot,
				}),
			}),
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
