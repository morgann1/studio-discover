--!strict

local ChangeHistoryService = game:GetService("ChangeHistoryService")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local createLogger = require(StudioDiscover.Source.Util.createLogger)
local permissionError = require(StudioDiscover.Source.Installer.permissionError)
local refreshInstalledRoots = require(StudioDiscover.Source.Installer.refreshInstalledRoots)
local runWithBusyLock = require(StudioDiscover.Source.Installer.runWithBusyLock)

local pesdeApplyAsync = require(StudioDiscover.Source.Installer.Pesde.applyAsync)
local pesdeLockfile = require(StudioDiscover.Source.Installer.Pesde.lockfile)
local pesdeResolveAsync = require(StudioDiscover.Source.Installer.Pesde.resolveAsync)
local pesdeSnapshotRoots = require(StudioDiscover.Source.Installer.Pesde.snapshotRoots)

local sharedTypes = require(StudioDiscover.Source.Installer.types)

local logger = createLogger.createLogger("pesde.installer.uninstall")

type Realm = sharedTypes.Realm

export type UninstallResult = {
	ok: boolean,
	error: string?,
}

local function runUninstall(scope: string, name: string, realm: Realm): UninstallResult
	logger.info(`uninstall pesde {scope}/{name} realm={realm}`)

	local priorSnapshots = pesdeSnapshotRoots()
	local remaining: { pesdeResolveAsync.RootRequest } = {}
	local didMatch = false
	for _, prior in priorSnapshots do
		if prior.realm == realm and prior.scope == scope and prior.name == name and prior.kind == "pesde" then
			didMatch = true
			logger.info(`removing root {prior.scope}/{prior.name}@{prior.version} (alias={prior.alias})`)
			continue
		end
		table.insert(remaining, {
			scope = prior.scope,
			name = prior.name,
			version = prior.version,
			realm = prior.realm,
			alias = prior.alias,
		})
	end

	if not didMatch then
		logger.warn(`no matching pesde root for {scope}/{name} in {realm}`)
		return {
			ok = false,
			error = `No installed pesde root matched {scope}/{name}`,
		}
	end

	logger.info(`resolve starting ({#remaining} remaining root(s))`)
	local resolved, rootAliases, resolutionFailures = pesdeResolveAsync(remaining, nil)
	for _, failure in resolutionFailures do
		logger.warn(`resolve failure: {failure}`)
	end

	local recordLabel = `Uninstall {scope}/{name}`
	local recordingId = ChangeHistoryService:TryBeginRecording(recordLabel)

	local applySuccess, applyOutcome = pcall(function()
		local failures = pesdeApplyAsync(resolved, rootAliases, nil)
		pesdeLockfile.save(resolved)
		return failures
	end)

	if not applySuccess then
		logger.error(`apply threw: {applyOutcome}`)
		if recordingId ~= nil then
			ChangeHistoryService:FinishRecording(recordingId, Enum.FinishRecordingOperation.Cancel)
		end
		return {
			ok = false,
			error = permissionError.describe(applyOutcome),
		}
	end

	if recordingId ~= nil then
		ChangeHistoryService:FinishRecording(recordingId, Enum.FinishRecordingOperation.Commit)
	end

	refreshInstalledRoots()

	logger.info(`uninstall succeeded: {scope}/{name}`)
	return {
		ok = true,
		error = nil,
	}
end

local function uninstallPesdeAsync(scope: string, name: string, realm: Realm): UninstallResult
	return runWithBusyLock(function(): UninstallResult
		logger.warn(`uninstall rejected: another installer operation is in progress`)
		return {
			ok = false,
			error = "Another installer operation is in progress.",
		}
	end, function(): UninstallResult
		return runUninstall(scope, name, realm)
	end, function(err): UninstallResult
		logger.error(`uninstall crashed for {scope}/{name}: {err}`)
		return {
			ok = false,
			error = `Uninstall failed: {err}`,
		}
	end)
end

return uninstallPesdeAsync
