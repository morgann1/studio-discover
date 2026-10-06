--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Dialog = Foundation.Dialog
const ButtonVariant = Foundation.Enums.ButtonVariant
const DialogSize = Foundation.Enums.DialogSize
const Orientation = Foundation.Enums.Orientation

const e = React.createElement

--[[
	Asks the user to confirm an action, with Cancel beside the confirm button. Render
		it while the question is open; both buttons and the backdrop leave closing to
		the caller.

	A destructive action gets the alert button.
]]
const function ConfirmDialog(props: {
	read title: string,
	read body: string,
	read confirmText: string,
	read isDestructive: boolean?,
	read onConfirm: () -> (),
	read onCancel: () -> (),
})
	return e(Dialog.Root, {
		size = DialogSize.Small,
		disablePortal = false,
		hasBackdrop = true,
		onClose = props.onCancel,
	}, {
		DialogTitle = e(Dialog.Title, {
			text = props.title,
		}),
		DialogContent = e(Dialog.Content, {}, {
			Body = e(Dialog.Text, {
				Text = props.body,
			}),
		}),
		DialogActions = e(Dialog.Actions, {
			orientation = Orientation.Horizontal,
			actions = {
				{ text = "Cancel", variant = ButtonVariant.Standard, onActivated = props.onCancel },
				{
					text = props.confirmText,
					variant = if props.isDestructive then ButtonVariant.Alert else ButtonVariant.Emphasis,
					onActivated = props.onConfirm,
				},
			},
		}),
	})
end

return ConfirmDialog
