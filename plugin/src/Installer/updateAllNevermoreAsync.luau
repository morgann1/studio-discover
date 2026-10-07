--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const applyRootsAsync = require(StudioDiscover.Source.Installer.applyRootsAsync)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const types = require(StudioDiscover.Source.Installer.types)
const unresolvedRootsError = require(StudioDiscover.Source.Installer.unresolvedRootsError)

const nevermoreApplyAsync = require(StudioDiscover.Libraries.NevermoreRegistry.applyAsync)
const nevermoreResolveAsync = require(StudioDiscover.Libraries.NevermoreRegistry.resolveAsync)
const nevermoreSnapshotRoots = require(StudioDiscover.Libraries.NevermoreRegistry.snapshotRoots)
const saveNevermoreLockfileAsync = require(StudioDiscover.Libraries.NevermoreRegistry.saveLockfileAsync)

const logger = createLogger.createLogger("nevermore.installer.updateAll")

const function findUpdate(updates: { types.UpdateInfo }, root: coreTypes.RootRequest): types.UpdateInfo?
	for _, update in updates do
		if update.scope == root.scope and update.name == root.name then
			return update
		end
	end

	return nil
end

--[[
	The Nevermore part of `updateAllAsync`, which runs it under the busy lock. Moves
		each matching Nevermore root to its latest version in one resolve and apply.
]]
const function updateAllNevermoreAsync(updates: { types.UpdateInfo }): types.OperationResult
	logger.info(`updateAll starting ({#updates} Nevermore package(s))`)

	const nextRoots: { coreTypes.RootRequest } = {}
	local appliedCount = 0
	for _, prior in nevermoreSnapshotRoots() do
		const update = findUpdate(updates, prior)
		if update ~= nil then
			logger.info(`bumping {prior.scope}/{prior.name} {prior.version} -> {update.latestVersion}`)
			appliedCount += 1
		end

		table.insert(nextRoots, {
			scope = prior.scope,
			name = prior.name,
			version = if update ~= nil then update.latestVersion else prior.version,
			requestRealm = prior.requestRealm,
			alias = prior.alias,
		})
	end

	if appliedCount == 0 then
		logger.warn("updateAll nevermore: no installed roots matched")

		return {
			ok = false,
			error = "No installed Nevermore packages matched the update list",
			failures = {},
		}
	end

	-- Like `npm update`, an update ignores the lockfile and resolves every dependency again.
	const resolved, rootIds, resolutionFailures, unresolvedRoots = nevermoreResolveAsync(nextRoots, {}, nil)
	for _, failure in resolutionFailures do
		logger.warn(`resolve failure: {failure}`)
	end

	const unresolvedError = unresolvedRootsError(unresolvedRoots, resolutionFailures)
	if unresolvedError ~= nil then
		return {
			ok = false,
			error = unresolvedError,
			failures = resolutionFailures,
		}
	end

	return applyRootsAsync(`Update {appliedCount} Nevermore package(s)`, function()
		const failures = nevermoreApplyAsync(resolved, rootIds, nil)
		saveNevermoreLockfileAsync(resolved)

		return failures
	end)
end

return updateAllNevermoreAsync
