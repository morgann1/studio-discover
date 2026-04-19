--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local Installer = require(StudioDiscover.Source.Installer)
local Navigation = require(StudioDiscover.Source.Navigation)
local capitalize = require(StudioDiscover.Source.Util.capitalize)
local createNextOrder = require(StudioDiscover.Source.Util.createNextOrder)

local Button = Foundation.Button
local Text = Foundation.Text
local View = Foundation.View
local ButtonVariant = Foundation.Enums.ButtonVariant
local InputSize = Foundation.Enums.InputSize

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

	local onView = React.useCallback(function()
		Navigation.pushScreen("Package", {
			scope = props.scope,
			name = props.name,
		})
	end, { props.scope, props.name } :: { any })

	local onRemove = React.useCallback(function()
		setIsRemoving(true)
		task.spawn(function()
			Installer.uninstallAsync(props.scope, props.name, props.realm)
		end)
	end, { props.scope, props.name, props.realm } :: { any })

	local nextOrder = createNextOrder()

	return e(View, {
		tag = "size-full-0 auto-y row align-y-center gap-medium padding-medium bg-surface-200 radius-medium",
		onActivated = onView,
		LayoutOrder = props.LayoutOrder,
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
		Remove = e(Button, {
			text = if isRemoving then "Removing…" else "Remove",
			variant = ButtonVariant.Alert,
			size = InputSize.Small,
			isDisabled = isRemoving,
			onActivated = onRemove,
			LayoutOrder = nextOrder(),
		}),
	})
end

return Row
