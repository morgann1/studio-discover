--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const applyRootsAsync = require(StudioDiscover.Source.Installer.applyRootsAsync)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const types = require(StudioDiscover.Source.Installer.types)
const unresolvedRootsError = require(StudioDiscover.Source.Installer.unresolvedRootsError)

const pesdeApplyAsync = require(StudioDiscover.Libraries.PesdeRegistry.applyAsync)
const pesdeResolveAsync = require(StudioDiscover.Libraries.PesdeRegistry.resolveAsync)
const pesdeSnapshotRoots = require(StudioDiscover.Libraries.PesdeRegistry.snapshotRoots)
const savePesdeLockfileAsync = require(StudioDiscover.Libraries.PesdeRegistry.saveLockfileAsync)

const logger = createLogger.createLogger("pesde.installer.updateAll")

const function findUpdate(updates: { types.UpdateInfo }, snapshot: coreTypes.RootRequest): types.UpdateInfo?
	for _, update in updates do
		if
			update.realm == snapshot.requestRealm
			and update.scope == snapshot.scope
			and update.name == snapshot.name
		then
			return update
		end
	end

	return nil
end

--[[
	The pesde half of `updateAllAsync`, which runs it under the busy lock. Moves each
		matching pesde root to its latest version in one resolve and apply.
]]
const function updateAllPesdeAsync(updates: { types.UpdateInfo }): types.OperationResult
	logger.info(`updateAll starting ({#updates} pesde package(s))`)

	const nextRoots: { coreTypes.RootRequest } = {}
	local appliedCount = 0
	for _, prior in pesdeSnapshotRoots() do
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
		logger.warn("updateAll pesde: no installed roots matched")

		return {
			ok = false,
			error = "No installed pesde packages matched the update list",
			failures = {},
		}
	end

	const resolved, rootAliases, resolutionFailures, unresolvedRoots = pesdeResolveAsync(nextRoots, nil)
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

	return applyRootsAsync(`Update {appliedCount} pesde package(s)`, function()
		const failures = pesdeApplyAsync(resolved, rootAliases, nil)
		savePesdeLockfileAsync(resolved)

		return failures
	end)
end

return updateAllPesdeAsync
