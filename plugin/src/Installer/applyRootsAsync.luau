--!strict

const ChangeHistoryService = game:GetService("ChangeHistoryService")

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const createLogger = require(StudioDiscover.Core.createLogger)
const permissionError = require(StudioDiscover.Source.Installer.permissionError)
const refreshInstalledRoots = require(StudioDiscover.Source.Installer.refreshInstalledRoots)
const types = require(StudioDiscover.Source.Installer.types)

const logger = createLogger.createLogger("installer.applyRoots")

const function hasPrefix(failures: { string }, prefix: string): boolean
	for _, failure in failures do
		if string.sub(failure, 1, #prefix) == prefix then
			return true
		end
	end

	return false
end

--[[
	Runs one registry's apply inside a single ChangeHistory recording, so the user can
		undo the whole operation. `applyAsync` writes the tree and the lockfile, and
		returns the non-fatal failures, each prefixed with the package it came from.

	When `applyAsync` throws, or a failure starts with `rootFailurePrefix`, the
		recording is cancelled and the place is left as it was. Every install,
		uninstall, and update for both registries goes through here.
]]
const function applyRootsAsync(
	recordLabel: string,
	applyAsync: () -> { string },
	rootFailurePrefix: string?
): types.OperationResult
	const recordingId = ChangeHistoryService:TryBeginRecording(recordLabel)
	if recordingId == nil then
		logger.warn(`could not begin ChangeHistory recording for "{recordLabel}"; will not be undoable`)
	end

	const applySuccess, applyOutcome = pcall(applyAsync)

	if not applySuccess then
		logger.error(`apply threw for "{recordLabel}": {applyOutcome}`)

		if recordingId ~= nil then
			ChangeHistoryService:FinishRecording(recordingId, Enum.FinishRecordingOperation.Cancel)
		end

		return {
			ok = false,
			error = permissionError(applyOutcome),
			failures = {},
		}
	end

	for _, failure in applyOutcome do
		logger.warn(`apply failure: {failure}`)
	end

	const rootFailed = rootFailurePrefix ~= nil and hasPrefix(applyOutcome, rootFailurePrefix)
	if recordingId ~= nil then
		const operation = if rootFailed
			then Enum.FinishRecordingOperation.Cancel
			else Enum.FinishRecordingOperation.Commit
		ChangeHistoryService:FinishRecording(recordingId, operation)
	end

	if rootFailed then
		return {
			ok = false,
			error = "the requested package did not apply, so nothing was changed",
			failures = applyOutcome,
		}
	end

	refreshInstalledRoots()

	return {
		ok = true,
		failures = applyOutcome,
	}
end

return applyRootsAsync
