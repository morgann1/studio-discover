--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)
const React = require(StudioDiscover.Packages.React)

const Installer = require(StudioDiscover.Source.Installer)
const NoticeStore = require(StudioDiscover.Source.NoticeStore)
const installerTypes = require(StudioDiscover.Source.Installer.types)
const plural = require(StudioDiscover.Source.Util.plural)
const useOperation = require(StudioDiscover.Source.Common.useOperation)

const Alert = Foundation.Alert
const View = Foundation.View
const AlertSeverity = Foundation.Enums.AlertSeverity
const AlertVariant = Foundation.Enums.AlertVariant

const e = React.createElement

--[[
	How many updates are waiting, with Update all, and how many installed packages
		couldn't be checked, with Try again. While the updates run it says so in place
		of the actions, and a failure replaces it until dismissed. While `isChecking`,
		it says updates are being checked, so a refresh shows it ran. Renders nothing
		when every package was checked and none has an update.
]]
const function UpdatesAlert(props: {
	read updates: { installerTypes.UpdateInfo },
	read failed: number,
	read isChecking: boolean,
	read LayoutOrder: number?,
}): React.Node
	const operation = useOperation()
	const isBusy = Installer.useIsBusy()
	const updates = props.updates
	const failed = props.failed
	const errorText = operation.error

	const tryAgain = { text = "Try again", onActivated = Installer.refreshInstalledRoots }

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
	elseif props.isChecking then
		alert = e(Alert, {
			variant = AlertVariant.Feedback,
			severity = AlertSeverity.Info,
			text = "Checking for updates...",
		})
	elseif #updates == 0 and failed == 0 then
		return nil
	elseif #updates == 0 then
		alert = e(Alert, {
			variant = AlertVariant.Feedback,
			severity = AlertSeverity.Warning,
			text = `Couldn't check {plural(failed, "package")} for updates.`,
			actions = { primary = tryAgain },
		})
	else
		const available = `{plural(#updates, "update")} available`

		alert = e(Alert, {
			variant = AlertVariant.Feedback,
			severity = if failed > 0 then AlertSeverity.Warning else AlertSeverity.Info,
			text = if failed > 0 then `{available}. Couldn't check {plural(failed, "package")}.` else available,
			actions = if isBusy
				then nil
				else {
					primary = {
						text = "Update all",
						onActivated = function()
							operation.run(function()
								const result = Installer.updateAllAsync(updates)
								NoticeStore.showSuccess(result, `Updated {plural(#updates, "package")}`)

								return result
							end)
						end,
					},
					secondary = if failed > 0 then tryAgain else nil,
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
