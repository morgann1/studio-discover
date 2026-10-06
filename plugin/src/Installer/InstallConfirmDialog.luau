--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const React = require(StudioDiscover.Packages.React)

const ConfirmDialog = require(StudioDiscover.Source.Common.ConfirmDialog)
const capitalize = require(StudioDiscover.Source.Util.capitalize)
const registryLabel = require(StudioDiscover.Source.Util.registryLabel)
const types = require(StudioDiscover.Source.Installer.types)

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

	return e(ConfirmDialog, {
		title = "Install package?",
		body = body,
		confirmText = "Install",
		onConfirm = props.onConfirm,
		onCancel = props.onCancel,
	})
end

return InstallConfirmDialog
