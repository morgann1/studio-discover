--!strict

local ChangeHistoryService = game:GetService("ChangeHistoryService")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local applyAsync = require(StudioDiscover.Source.Installer.applyAsync)
local createLogger = require(StudioDiscover.Source.Util.createLogger)
local installerAtom = require(StudioDiscover.Source.Installer.installerAtom)
local lockfile = require(StudioDiscover.Source.Installer.lockfile)
local packageId = require(StudioDiscover.Source.Installer.packageId)
local resolveAsync = require(StudioDiscover.Source.Installer.resolveAsync)
local types = require(StudioDiscover.Source.Installer.types)

local logger = createLogger.createLogger("installer.install")

local function countPairs(t: { [any]: any }): number
	local count = 0
	for _ in t do
		count += 1
	end
	return count
end

type Realm = "shared" | "server"
type RootRequest = types.RootRequest
type InstallerState = types.InstallerState

export type InstallResult = {
	ok: boolean,
	error: string?,
	failures: { string },
}

-- Installs a single package as a new root into the project. Currently
-- phase (a): add-only — no snapshot of prior roots yet, no re-resolve of
-- sibling packages. Subsequent installs overwrite the root set with just
-- the new package. Multi-package support lands when we wire install into a
-- project manifest.
local function installAsync(scope: string, name: string, version: string, alias: string, realm: Realm?): InstallResult
	logger.info(`install {scope}/{name}@{version} alias={alias} realm={realm or "shared"}`)

	local function setState(next: InstallerState)
		installerAtom(next)
	end

	local function progress(message: string)
		local current = installerAtom()
		logger.debug(`progress: {message}`)
		setState({
			status = current.status,
			message = message,
			errors = current.errors,
		})
	end

	if realm == "dev" :: any then
		logger.warn(`rejecting dev realm package {scope}/{name}@{version}`)
		local result: InstallResult = {
			ok = false,
			error = "Dev realm packages are not supported.",
			failures = {},
		}
		setState({
			status = "error",
			message = result.error,
			errors = {},
		})
		return result
	end

	setState({
		status = "running",
		message = "Resolving dependencies...",
		errors = {},
	})

	local root: RootRequest = {
		scope = scope,
		name = name,
		version = version,
		requestRealm = realm or "shared",
		alias = alias,
	}

	local roots: { RootRequest } = { root }
	local lockData = lockfile.load()
	logger.info(`resolve starting ({#roots} root(s), lockfile has {countPairs(lockData)} entries)`)
	local resolved, rootAliases, resolutionFailures = resolveAsync(roots, lockData, progress)

	if #resolutionFailures > 0 then
		for _, failure in resolutionFailures do
			logger.warn(`resolve failure: {failure}`)
		end
	end

	local rootPackageId = packageId.format(scope, name, version)
	if resolved[rootPackageId] == nil then
		local message = `Failed to resolve {scope}/{name}@{version}`
		if #resolutionFailures > 0 then
			message = `{message} ({table.concat(resolutionFailures, "; ")})`
		end
		logger.warn(`install aborted: {message}`)
		local result: InstallResult = {
			ok = false,
			error = message,
			failures = resolutionFailures,
		}
		setState({
			status = "error",
			message = message,
			errors = resolutionFailures,
		})
		return result
	end

	logger.info(`resolve complete: {countPairs(resolved)} package(s) activated`)

	-- Wrap DataModel mutations in a ChangeHistory recording so users can
	-- Ctrl+Z the entire install as one step. Bail out of the waypoint on
	-- error so the partial state doesn't land on the undo stack.
	local recordingId = ChangeHistoryService:TryBeginRecording(`Install {scope}/{name}@{version}`)
	if recordingId == nil then
		logger.warn("could not begin ChangeHistory recording; install will not be undoable")
	end

	logger.info("apply starting")
	local applySuccess, applyOutcome = pcall(function()
		local failures = applyAsync(resolved, rootAliases, progress)
		lockfile.save(resolved)
		return failures
	end)

	if not applySuccess then
		logger.error(`apply threw: {applyOutcome}`)
		if recordingId ~= nil then
			ChangeHistoryService:FinishRecording(recordingId, Enum.FinishRecordingOperation.Cancel)
		end
		local message = `Install failed: {applyOutcome}`
		setState({
			status = "error",
			message = message,
			errors = resolutionFailures,
		})
		return {
			ok = false,
			error = message,
			failures = resolutionFailures,
		}
	end

	local applyFailures: { string } = applyOutcome :: { string }
	if #applyFailures > 0 then
		for _, failure in applyFailures do
			logger.warn(`apply failure: {failure}`)
		end
	end
	logger.info(`apply complete ({#applyFailures} non-fatal warning(s))`)

	if recordingId ~= nil then
		ChangeHistoryService:FinishRecording(recordingId, Enum.FinishRecordingOperation.Commit)
	end

	local allFailures: { string } = {}
	for _, failure in resolutionFailures do
		table.insert(allFailures, failure)
	end
	for _, failure in applyFailures do
		table.insert(allFailures, failure)
	end

	logger.info(`install succeeded: {scope}/{name}@{version}`)

	setState({
		status = "success",
		message = if #allFailures > 0
			then `Installed with {#allFailures} warning(s)`
			else `Installed {scope}/{name}@{version}`,
		errors = allFailures,
	})

	return {
		ok = true,
		error = nil,
		failures = allFailures,
	}
end

return installAsync
