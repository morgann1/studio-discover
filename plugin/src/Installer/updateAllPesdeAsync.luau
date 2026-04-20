--!strict

local ChangeHistoryService = game:GetService("ChangeHistoryService")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local createLogger = require(StudioDiscover.Source.Util.createLogger)
local refreshInstalledRoots = require(StudioDiscover.Source.Installer.refreshInstalledRoots)

local pesdeApplyAsync = require(StudioDiscover.Source.Installer.Pesde.applyAsync)
local pesdeLockfile = require(StudioDiscover.Source.Installer.Pesde.lockfile)
local pesdeResolveAsync = require(StudioDiscover.Source.Installer.Pesde.resolveAsync)
local pesdeSnapshotRoots = require(StudioDiscover.Source.Installer.Pesde.snapshotRoots)

local sharedTypes = require(StudioDiscover.Source.Installer.types)

local logger = createLogger.createLogger("installer.updatePesde")

type Realm = sharedTypes.Realm

export type PesdeUpdateRequest = {
	scope: string,
	name: string,
	realm: Realm,
	version: string,
}

export type UpdateAllResult = {
	ok: boolean,
	error: string?,
	failures: { string },
}

local function findMatch(
	updates: { PesdeUpdateRequest },
	scope: string,
	name: string,
	realm: Realm
): PesdeUpdateRequest?
	for _, update in updates do
		if update.realm == realm and update.scope == scope and update.name == name then
			return update
		end
	end
	return nil
end

local function updateAllPesdeAsync(updates: { PesdeUpdateRequest }): UpdateAllResult
	if #updates == 0 then
		return { ok = true, error = nil, failures = {} }
	end

	logger.info(`updateAll starting ({#updates} pesde package(s))`)

	local priorSnapshots = pesdeSnapshotRoots()
	local nextRoots: { pesdeResolveAsync.RootRequest } = {}
	local appliedCount = 0
	for _, prior in priorSnapshots do
		if prior.kind ~= "pesde" then
			table.insert(nextRoots, {
				scope = prior.scope,
				name = prior.name,
				version = prior.version,
				realm = prior.realm,
				alias = prior.alias,
			})
			continue
		end
		local match = findMatch(updates, prior.scope, prior.name, prior.realm)
		if match ~= nil then
			logger.info(`bumping {prior.scope}/{prior.name} {prior.version} -> {match.version}`)
			table.insert(nextRoots, {
				scope = prior.scope,
				name = prior.name,
				version = match.version,
				realm = prior.realm,
				alias = prior.alias,
			})
			appliedCount += 1
		else
			table.insert(nextRoots, {
				scope = prior.scope,
				name = prior.name,
				version = prior.version,
				realm = prior.realm,
				alias = prior.alias,
			})
		end
	end

	if appliedCount == 0 then
		logger.warn("updateAll pesde: no installed roots matched")
		return {
			ok = false,
			error = "No installed pesde packages matched the update list",
			failures = {},
		}
	end

	local resolved, rootAliases, resolutionFailures = pesdeResolveAsync(nextRoots, nil)
	for _, failure in resolutionFailures do
		logger.warn(`resolve failure: {failure}`)
	end

	local recordLabel = `Update {appliedCount} pesde package(s)`
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
			error = tostring(applyOutcome),
			failures = resolutionFailures,
		}
	end

	if recordingId ~= nil then
		ChangeHistoryService:FinishRecording(recordingId, Enum.FinishRecordingOperation.Commit)
	end

	refreshInstalledRoots()

	local applyFailures: { string } = applyOutcome :: { string }
	local all: { string } = {}
	for _, f in resolutionFailures do
		table.insert(all, f)
	end
	for _, f in applyFailures do
		table.insert(all, f)
	end

	logger.info(`updateAll pesde succeeded ({appliedCount} package(s), {#all} warning(s))`)
	return {
		ok = true,
		error = nil,
		failures = all,
	}
end

return updateAllPesdeAsync
