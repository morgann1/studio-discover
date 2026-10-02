--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const applyRootsAsync = require(StudioDiscover.Source.Installer.applyRootsAsync)
const createLogger = require(StudioDiscover.Core.createLogger)
const types = require(StudioDiscover.Source.Installer.types)

const pesdeApplyAsync = require(StudioDiscover.PesdeRegistry.applyAsync)
const pesdeLockfile = require(StudioDiscover.PesdeRegistry.lockfile)
const pesdeResolveAsync = require(StudioDiscover.PesdeRegistry.resolveAsync)
const pesdeSnapshotRoots = require(StudioDiscover.PesdeRegistry.snapshotRoots)

const logger = createLogger.createLogger("pesde.installer.updateAll")

const function findUpdate(
	updates: { types.UpdateInfo },
	snapshot: pesdeSnapshotRoots.PesdeRootSnapshot
): types.UpdateInfo?
	if snapshot.kind ~= "pesde" then
		return nil
	end

	for _, update in updates do
		if update.realm == snapshot.realm and update.scope == snapshot.scope and update.name == snapshot.name then
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

	const nextRoots: { pesdeResolveAsync.RootRequest } = {}
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
			realm = prior.realm,
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

	const resolved, rootAliases, resolutionFailures = pesdeResolveAsync(nextRoots, nil)
	for _, failure in resolutionFailures do
		logger.warn(`resolve failure: {failure}`)
	end

	return applyRootsAsync(`Update {appliedCount} pesde package(s)`, function()
		const failures = pesdeApplyAsync(resolved, rootAliases, nil)
		pesdeLockfile.save(resolved)

		return failures
	end)
end

return updateAllPesdeAsync
