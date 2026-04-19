--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local Installer = require(StudioDiscover.Source.Installer)
local Navigation = require(StudioDiscover.Source.Navigation)
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
	realm: Realm,
	installedVersion: string,
	latestVersion: string,
	LayoutOrder: number?,
}

local function Row(props: Props)
	local isUpdating, setIsUpdating = React.useState(false)

	local onView = React.useCallback(function()
		Navigation.pushScreen("Package", {
			scope = props.scope,
			name = props.name,
		})
	end, { props.scope, props.name } :: { any })

	local onUpdate = React.useCallback(function()
		setIsUpdating(true)
		task.spawn(function()
			Installer.updateAllAsync({
				{
					scope = props.scope,
					name = props.name,
					realm = props.realm,
					version = props.latestVersion,
				},
			})
		end)
	end, { props.scope, props.name, props.realm, props.latestVersion } :: { any })

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
			Delta = e(Text, {
				tag = "size-full-0 auto-y text-body-small content-muted text-align-x-left",
				Text = `v{props.installedVersion}  →  v{props.latestVersion}`,
			}),
		}),
		Update = e(Button, {
			text = if isUpdating then "Updating…" else "Update",
			variant = ButtonVariant.Emphasis,
			size = InputSize.Small,
			isDisabled = isUpdating,
			onActivated = onUpdate,
			LayoutOrder = nextOrder(),
		}),
	})
end

return Row
