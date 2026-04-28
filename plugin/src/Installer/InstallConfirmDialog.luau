--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Foundation = require(StudioDiscover.Packages.Foundation)
local React = require(StudioDiscover.Packages.React)

local apiTypes = require(StudioDiscover.Source.Api.types)
local capitalize = require(StudioDiscover.Source.Util.capitalize)
local types = require(StudioDiscover.Source.Installer.types)

local Dialog = Foundation.Dialog
local ButtonVariant = Foundation.Enums.ButtonVariant
local DialogSize = Foundation.Enums.DialogSize
local Orientation = Foundation.Enums.Orientation

local e = React.createElement

type Realm = types.Realm
type Registry = apiTypes.Registry

local REGISTRY_LABELS: { [Registry]: string } = {
	wally = "Wally",
	pesde = "pesde",
}

type Props = {
	scope: string,
	name: string,
	version: string,
	registry: Registry,
	realm: Realm,
	onConfirm: () -> (),
	onCancel: () -> (),
}

local function InstallConfirmDialog(props: Props)
	local registryLabel = REGISTRY_LABELS[props.registry] or props.registry
	local realmLabel = capitalize(props.realm)
	local body = `Install {props.scope}/{props.name} v{props.version} from {registryLabel}? `
		.. `Luau source will be fetched and written into the {realmLabel} packages folder of this place.`

	return e(Dialog.Root, {
		size = DialogSize.Small,
		hasBackdrop = true,
		onClose = props.onCancel,
	}, {
		DialogTitle = e(Dialog.Title, {
			text = "Install package?",
		}),
		DialogContent = e(Dialog.Content, {}, {
			Body = e(Dialog.Text, {
				Text = body,
			}),
		}),
		DialogActions = e(Dialog.Actions, {
			orientation = Orientation.Horizontal,
			actions = {
				{ text = "Cancel", variant = ButtonVariant.Standard, onActivated = props.onCancel },
				{ text = "Install", variant = ButtonVariant.Emphasis, onActivated = props.onConfirm },
			},
		}),
	})
end

return InstallConfirmDialog
