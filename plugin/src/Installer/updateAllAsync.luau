--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const applyAsync = require(StudioDiscover.Libraries.WallyRegistry.applyAsync)
const applyRootsAsync = require(StudioDiscover.Source.Installer.applyRootsAsync)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const lockfile = require(StudioDiscover.Libraries.WallyRegistry.lockfile)
const registries = require(StudioDiscover.Libraries.Core.registries)
const resolveAsync = require(StudioDiscover.Libraries.WallyRegistry.resolveAsync)
const runWithBusyLock = require(StudioDiscover.Source.Installer.runWithBusyLock)
const snapshotRoots = require(StudioDiscover.Libraries.WallyRegistry.snapshotRoots)
const types = require(StudioDiscover.Source.Installer.types)
const unresolvedRootsError = require(StudioDiscover.Source.Installer.unresolvedRootsError)
const updateAllNevermoreAsync = require(StudioDiscover.Source.Installer.updateAllNevermoreAsync)
const updateAllPesdeAsync = require(StudioDiscover.Source.Installer.updateAllPesdeAsync)

const logger = createLogger.createLogger("wally.installer.updateAll")

const function findUpdate(updates: { types.UpdateInfo }, root: coreTypes.RootRequest): types.UpdateInfo?
	for _, update in updates do
		if update.realm == root.requestRealm and update.scope == root.scope and update.name == root.name then
			return update
		end
	end

	return nil
end

const function updateWallyAsync(updates: { types.UpdateInfo }): types.OperationResult
	logger.info(`updateAll starting ({#updates} wally package(s))`)

	const nextRoots: { coreTypes.RootRequest } = {}
	local appliedCount = 0
	for _, prior in snapshotRoots() do
		const update = findUpdate(updates, prior)
		if update == nil then
			table.insert(nextRoots, prior)
			continue
		end

		logger.info(`bumping {prior.scope}/{prior.name} {prior.version} -> {update.latestVersion}`)
		appliedCount += 1

		table.insert(nextRoots, {
			scope = prior.scope,
			name = prior.name,
			version = update.latestVersion,
			requestRealm = prior.requestRealm,
			alias = prior.alias,
		})
	end

	if appliedCount == 0 then
		logger.warn("updateAll: no installed wally roots matched the requested updates")

		return {
			ok = false,
			error = "No installed packages matched the update list",
			failures = {},
		}
	end

	const lockData = lockfile.load()
	const resolved, rootAliases, resolutionFailures, unresolvedRoots = resolveAsync(nextRoots, lockData, nil)
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

	return applyRootsAsync(`Update {appliedCount} package(s)`, function()
		const failures = applyAsync(resolved, rootAliases, nil)
		lockfile.saveAsync(resolved)

		return failures
	end)
end

-- Each registry's part of an update, which moves its roots in one resolve and apply.
const UPDATERS: { [coreTypes.Registry]: (updates: { types.UpdateInfo }) -> types.OperationResult } = {
	wally = updateWallyAsync,
	pesde = updateAllPesdeAsync,
	nevermore = updateAllNevermoreAsync,
}

const function runUpdateAllAsync(updates: { types.UpdateInfo }): types.OperationResult
	const failures: { string } = {}
	local errorMessage: string? = nil

	-- A crash in one registry's updates is caught here, so the other registries still update.
	for _, registry in registries do
		const registryUpdates: { types.UpdateInfo } = {}
		for _, update in updates do
			if update.registry == registry then
				table.insert(registryUpdates, update)
			end
		end

		if #registryUpdates == 0 then
			continue
		end

		const ok, outcome = pcall(UPDATERS[registry], registryUpdates)
		if not ok then
			logger.error(`{registry} updates crashed: {outcome}`)
			errorMessage = `{registry} updates failed: {outcome}`
			table.insert(failures, tostring(outcome))
			continue
		end

		table.move(outcome.failures, 1, #outcome.failures, #failures + 1, failures)
		if not outcome.ok then
			errorMessage = outcome.error
		end
	end

	if errorMessage ~= nil then
		return {
			ok = false,
			error = errorMessage,
			failures = failures,
		}
	end

	return {
		ok = true,
		failures = failures,
	}
end

-- Moves each installed root in `updates` to its latest version, for every registry.
const function updateAllAsync(updates: { types.UpdateInfo }): types.OperationResult
	if #updates == 0 then
		return {
			ok = true,
			failures = {},
		}
	end

	return runWithBusyLock("Update", function()
		return runUpdateAllAsync(updates)
	end)
end

return updateAllAsync
