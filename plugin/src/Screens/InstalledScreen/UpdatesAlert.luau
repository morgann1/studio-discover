--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Installer = require(StudioDiscover.Source.Installer)
const installerTypes = require(StudioDiscover.Source.Installer.types)
const plural = require(StudioDiscover.Source.Util.plural)
const useOperation = require(StudioDiscover.Source.Common.useOperation)

const Alert = Foundation.Alert
const View = Foundation.View
const AlertSeverity = Foundation.Enums.AlertSeverity
const AlertVariant = Foundation.Enums.AlertVariant

const e = React.createElement

--[[
	How many updates are waiting, with Update all. While the updates run it says so in
		place of the action, and a failure replaces it until dismissed. Renders nothing
		when there is nothing to say.
]]
const function UpdatesAlert(props: {
	read updates: { installerTypes.UpdateInfo },
	read LayoutOrder: number?,
}): React.Node
	const operation = useOperation()
	const isBusy = Installer.useIsBusy()
	const updates = props.updates
	const errorText = operation.error

	local alert: React.Node
	if errorText ~= nil then
		alert = e(Alert, {
			variant = AlertVariant.Feedback,
			severity = AlertSeverity.Error,
			text = errorText,
			onClose = operation.clearError,
		})
	elseif operation.isRunning then
		alert = e(Alert, {
			variant = AlertVariant.Feedback,
			severity = AlertSeverity.Info,
			text = `Updating {plural(#updates, "package")}...`,
		})
	elseif #updates == 0 then
		return nil
	elseif isBusy then
		alert = e(Alert, {
			variant = AlertVariant.Feedback,
			severity = AlertSeverity.Info,
			text = `{plural(#updates, "update")} available`,
		})
	else
		alert = e(Alert, {
			variant = AlertVariant.Feedback,
			severity = AlertSeverity.Info,
			text = `{plural(#updates, "update")} available`,
			actions = {
				primary = {
					text = "Update all",
					onActivated = function()
						operation.run(function()
							return Installer.updateAllAsync(updates)
						end)
					end,
				},
			},
		})
	end

	return e(View, {
		tag = "size-full-0 auto-y padding-x-large padding-bottom-medium",
		LayoutOrder = props.LayoutOrder,
	}, {
		Alert = alert,
	})
end

return UpdatesAlert
