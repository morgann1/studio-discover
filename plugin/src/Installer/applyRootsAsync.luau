--!strict

local ChangeHistoryService = game:GetService("ChangeHistoryService")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local applyAsync = require(StudioDiscover.Source.Installer.applyAsync)
local createLogger = require(StudioDiscover.Source.Util.createLogger)
local lockfile = require(StudioDiscover.Source.Installer.lockfile)
local refreshInstalledRoots = require(StudioDiscover.Source.Installer.refreshInstalledRoots)
local types = require(StudioDiscover.Source.Installer.types)

local logger = createLogger.createLogger("installer.applyRoots")

type ResolvedPackage = types.ResolvedPackage
type ProgressCallback = types.ProgressCallback

export type ApplyRootsResult = {
	ok: boolean,
	error: string?,
	failures: { string },
}

-- `decideCommit` can veto the waypoint after inspecting per-package failures;
-- returning false cancels the ChangeHistory recording and skips the refresh.
local function applyRootsAsync(
	resolved: { [string]: ResolvedPackage },
	rootAliases: { [string]: string },
	recordLabel: string,
	progress: ProgressCallback?,
	decideCommit: (({ string }) -> boolean)?
): ApplyRootsResult
	local recordingId = ChangeHistoryService:TryBeginRecording(recordLabel)
	if recordingId == nil then
		logger.warn(`could not begin ChangeHistory recording for "{recordLabel}"; will not be undoable`)
	end

	local applySuccess, applyOutcome = pcall(function()
		local failures = applyAsync(resolved, rootAliases, progress)
		lockfile.save(resolved)
		return failures
	end)

	if not applySuccess then
		logger.error(`apply threw for "{recordLabel}": {applyOutcome}`)
		if recordingId ~= nil then
			ChangeHistoryService:FinishRecording(recordingId, Enum.FinishRecordingOperation.Cancel)
		end
		return {
			ok = false,
			error = tostring(applyOutcome),
			failures = {},
		}
	end

	local applyFailures: { string } = applyOutcome :: { string }
	for _, failure in applyFailures do
		logger.warn(`apply failure: {failure}`)
	end

	local shouldCommit = if decideCommit ~= nil then decideCommit(applyFailures) else true
	if recordingId ~= nil then
		local op = if shouldCommit then Enum.FinishRecordingOperation.Commit else Enum.FinishRecordingOperation.Cancel
		ChangeHistoryService:FinishRecording(recordingId, op)
	end

	if shouldCommit then
		refreshInstalledRoots()
	end

	return {
		ok = shouldCommit,
		error = if shouldCommit then nil else "Root package did not apply",
		failures = applyFailures,
	}
end

return applyRootsAsync
