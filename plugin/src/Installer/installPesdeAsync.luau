--!strict

local ChangeHistoryService = game:GetService("ChangeHistoryService")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local SettingsStore = require(StudioDiscover.Source.SettingsStore)

local busyAtom = require(StudioDiscover.Source.Installer.busyAtom)
local createLogger = require(StudioDiscover.Source.Util.createLogger)
local formatName = require(StudioDiscover.Source.Util.formatName)
local installerAtom = require(StudioDiscover.Source.Installer.installerAtom)
local permissionError = require(StudioDiscover.Source.Installer.permissionError)
local refreshInstalledRoots = require(StudioDiscover.Source.Installer.refreshInstalledRoots)

local pesdeApplyAsync = require(StudioDiscover.Source.Installer.Pesde.applyAsync)
local pesdeLockfile = require(StudioDiscover.Source.Installer.Pesde.lockfile)
local pesdeResolveAsync = require(StudioDiscover.Source.Installer.Pesde.resolveAsync)
local pesdeSnapshotRoots = require(StudioDiscover.Source.Installer.Pesde.snapshotRoots)

local sharedTypes = require(StudioDiscover.Source.Installer.types)

local logger = createLogger.createLogger("installer.installPesde")

type Realm = sharedTypes.Realm
type InstallerState = sharedTypes.InstallerState
type InstallerTarget = sharedTypes.InstallerTarget

export type InstallResult = {
	ok: boolean,
	error: string?,
	failures: { string },
}

local function countPairs(t: { [any]: any }): number
	local count = 0
	for _ in t do
		count += 1
	end
	return count
end

local function installPesdeAsync(
	scope: string,
	name: string,
	version: string,
	alias: string,
	realm: Realm?
): InstallResult
	if busyAtom() then
		logger.warn(`install rejected: another installer operation is in progress`)
		return {
			ok = false,
			error = "Another installer operation is in progress.",
			failures = {},
		}
	end
	busyAtom(true)

	logger.info(`install pesde {scope}/{name}@{version} alias={alias} realm={realm or "shared"}`)

	local target: InstallerTarget = {
		scope = scope,
		name = name,
		version = version,
	}

	local function setState(next: InstallerState)
		installerAtom(next)
	end

	local function progress(message: string)
		local current = installerAtom()
		setState({
			status = current.status,
			message = message,
			errors = current.errors,
			target = target,
		})
	end

	setState({
		status = "running",
		message = "Resolving dependencies...",
		errors = {},
		target = target,
	})

	local effectiveRealm: Realm = realm or "shared"

	local settings = SettingsStore.get().getStorage()
	local override: string? = nil
	for _, rule in settings.displayNames do
		if rule.name == name and rule.displayName ~= "" then
			override = rule.displayName
			break
		end
	end
	local formattedAlias: string = if override ~= nil then override else formatName(alias, settings.namingConvention)

	local priorSnapshots = pesdeSnapshotRoots()
	local roots: { pesdeResolveAsync.RootRequest } = {}
	for _, prior in priorSnapshots do
		local samePackage = prior.realm == effectiveRealm and prior.scope == scope and prior.name == name
		if samePackage then
			logger.info(`replacing prior root {prior.scope}/{prior.name}@{prior.version}`)
			continue
		end
		table.insert(roots, {
			scope = prior.scope,
			name = prior.name,
			version = prior.version,
			realm = prior.realm,
			alias = prior.alias,
		})
	end

	local baseAlias = formattedAlias
	local finalAlias = formattedAlias
	local suffix = 2
	while true do
		local conflict = false
		for _, prior in roots do
			if prior.realm == effectiveRealm and prior.alias == finalAlias then
				conflict = true
				break
			end
		end
		if not conflict then
			break
		end
		finalAlias = `{baseAlias}{suffix}`
		suffix += 1
	end
	if finalAlias ~= baseAlias then
		logger.warn(`alias "{baseAlias}" collided; using "{finalAlias}" instead`)
	end

	table.insert(roots, {
		scope = scope,
		name = name,
		version = version,
		realm = effectiveRealm,
		alias = finalAlias,
	})

	logger.info(`resolve starting ({#roots} root(s))`)
	local resolved, rootAliases, resolutionFailures = pesdeResolveAsync(roots, progress)

	for _, failure in resolutionFailures do
		logger.warn(`resolve failure: {failure}`)
	end

	local rootMatches = false
	for pkgId in resolved do
		local pkg = resolved[pkgId]
		if pkg.scope == scope and pkg.name == name and pkg.version == version then
			rootMatches = true
			break
		end
	end
	if not rootMatches then
		local message = `Failed to resolve {scope}/{name}@{version}`
		if #resolutionFailures > 0 then
			message = `{message} ({table.concat(resolutionFailures, "; ")})`
		end
		setState({
			status = "error",
			message = message,
			errors = resolutionFailures,
			target = target,
		})
		busyAtom(false)
		return {
			ok = false,
			error = message,
			failures = resolutionFailures,
		}
	end

	logger.info(`resolve complete: {countPairs(resolved)} package(s)`)

	local recordLabel = `Install {scope}/{name}@{version}`
	local recordingId = ChangeHistoryService:TryBeginRecording(recordLabel)

	local applySuccess, applyOutcome = pcall(function()
		local failures = pesdeApplyAsync(resolved, rootAliases, progress)
		pesdeLockfile.save(resolved)
		return failures
	end)

	if not applySuccess then
		logger.error(`apply threw: {applyOutcome}`)
		if recordingId ~= nil then
			ChangeHistoryService:FinishRecording(recordingId, Enum.FinishRecordingOperation.Cancel)
		end
		local message = permissionError.describe(applyOutcome)
		setState({
			status = "error",
			message = message,
			errors = {},
			target = target,
		})
		busyAtom(false)
		return {
			ok = false,
			error = message,
			failures = {},
		}
	end

	local applyFailures: { string } = applyOutcome :: { string }
	local rootFailureMarker = ""
	for pkgId in resolved do
		local pkg = resolved[pkgId]
		if pkg.scope == scope and pkg.name == name and pkg.version == version then
			rootFailureMarker = `{pkgId}:`
			break
		end
	end
	local rootFailed = false
	for _, failure in applyFailures do
		if string.sub(failure, 1, #rootFailureMarker) == rootFailureMarker then
			rootFailed = true
			break
		end
	end

	local shouldCommit = not rootFailed
	if recordingId ~= nil then
		local op = if shouldCommit then Enum.FinishRecordingOperation.Commit else Enum.FinishRecordingOperation.Cancel
		ChangeHistoryService:FinishRecording(recordingId, op)
	end

	if shouldCommit then
		refreshInstalledRoots()
	end

	local allFailures: { string } = {}
	for _, f in resolutionFailures do
		table.insert(allFailures, f)
	end
	for _, f in applyFailures do
		table.insert(allFailures, f)
	end

	if not shouldCommit then
		local message = `Failed to install {scope}/{name}@{version}`
		setState({
			status = "error",
			message = message,
			errors = allFailures,
			target = target,
		})
		busyAtom(false)
		return {
			ok = false,
			error = message,
			failures = allFailures,
		}
	end

	logger.info(`install succeeded: {scope}/{name}@{version}`)
	setState({
		status = "success",
		message = if #allFailures > 0
			then `Installed with {#allFailures} warning(s)`
			else `Installed {scope}/{name}@{version}`,
		errors = allFailures,
		target = target,
	})
	busyAtom(false)
	return {
		ok = true,
		error = nil,
		failures = allFailures,
	}
end

return installPesdeAsync
