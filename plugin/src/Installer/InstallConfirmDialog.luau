--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const capitalize = require(StudioDiscover.Source.Util.capitalize)
const registryLabel = require(StudioDiscover.Source.Util.registryLabel)
const types = require(StudioDiscover.Source.Installer.types)

const Dialog = Foundation.Dialog
const ButtonVariant = Foundation.Enums.ButtonVariant
const DialogSize = Foundation.Enums.DialogSize
const Orientation = Foundation.Enums.Orientation

const e = React.createElement

-- Asks the user to confirm an install before anything is fetched or written.
const function InstallConfirmDialog(props: {
	read request: types.InstallRequest,
	read onConfirm: () -> (),
	read onCancel: () -> (),
})
	const request = props.request
	const body = `Install {request.scope}/{request.name} v{request.version} from {registryLabel(request.registry)}? `
		.. `Luau source will be fetched and written into the {capitalize(request.realm)} packages folder of this place.`

	return e(Dialog.Root, {
		size = DialogSize.Small,
		disablePortal = false,
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
