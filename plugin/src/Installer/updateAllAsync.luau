--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local applyRootsAsync = require(StudioDiscover.Source.Installer.applyRootsAsync)
local createLogger = require(StudioDiscover.Source.Util.createLogger)
local lockfile = require(StudioDiscover.Source.Installer.Wally.lockfile)
local resolveAsync = require(StudioDiscover.Source.Installer.Wally.resolveAsync)
local runWithBusyLock = require(StudioDiscover.Source.Installer.runWithBusyLock)
local snapshotRoots = require(StudioDiscover.Source.Installer.Wally.snapshotRoots)
local types = require(StudioDiscover.Source.Installer.types)
local updateAllPesdeAsync = require(StudioDiscover.Source.Installer.updateAllPesdeAsync)

local logger = createLogger.createLogger("wally.installer.updateAll")

type Realm = "shared" | "server"
type Registry = types.Registry
type RootRequest = types.RootRequest

export type UpdateRequest = {
	scope: string,
	name: string,
	realm: Realm,
	version: string,
	registry: Registry?,
}

export type UpdateAllResult = {
	ok: boolean,
	error: string?,
	failures: { string },
}

local function findMatch(updates: { UpdateRequest }, root: RootRequest): UpdateRequest?
	for _, update in updates do
		if update.realm == root.requestRealm and update.scope == root.scope and update.name == root.name then
			return update
		end
	end
	return nil
end

local function runUpdateAll(updates: { UpdateRequest }): UpdateAllResult
	local wallyUpdates: { UpdateRequest } = {}
	local pesdeUpdates: { updateAllPesdeAsync.PesdeUpdateRequest } = {}
	for _, update in updates do
		if update.registry == "pesde" then
			table.insert(pesdeUpdates, {
				scope = update.scope,
				name = update.name,
				realm = update.realm,
				version = update.version,
			})
		else
			table.insert(wallyUpdates, update)
		end
	end

	local combined: UpdateAllResult = { ok = true, error = nil, failures = {} }

	if #pesdeUpdates > 0 then
		local pesdeOk, pesdeOutcome = pcall(updateAllPesdeAsync, pesdeUpdates)
		if pesdeOk then
			local result = pesdeOutcome :: updateAllPesdeAsync.UpdateAllResult
			for _, f in result.failures do
				table.insert(combined.failures, f)
			end
			if not result.ok then
				combined.ok = false
				combined.error = result.error
			end
		else
			logger.error(`pesde updates crashed: {pesdeOutcome}`)
			combined.ok = false
			combined.error = `Pesde updates failed: {pesdeOutcome}`
			table.insert(combined.failures, tostring(pesdeOutcome))
		end
	end

	if #wallyUpdates == 0 then
		return combined
	end

	logger.info(`updateAll starting ({#wallyUpdates} wally package(s))`)

	local priorRoots = snapshotRoots()
	local nextRoots: { RootRequest } = {}
	local appliedCount = 0
	for _, prior in priorRoots do
		local match = findMatch(wallyUpdates, prior)
		if match ~= nil then
			logger.info(`bumping {prior.scope}/{prior.name} {prior.version} -> {match.version}`)
			table.insert(nextRoots, {
				scope = prior.scope,
				name = prior.name,
				version = match.version,
				requestRealm = prior.requestRealm,
				alias = prior.alias,
			})
			appliedCount += 1
		else
			table.insert(nextRoots, prior)
		end
	end

	if appliedCount == 0 then
		logger.warn("updateAll: no installed wally roots matched the requested updates")
		if not combined.ok or #combined.failures == 0 then
			combined.ok = false
			combined.error = combined.error or "No installed packages matched the update list"
		end
		return combined
	end

	local lockData = lockfile.load()
	local resolved, rootAliases, resolutionFailures = resolveAsync(nextRoots, lockData, nil)
	for _, failure in resolutionFailures do
		logger.warn(`resolve failure: {failure}`)
	end

	local result = applyRootsAsync(resolved, rootAliases, `Update {appliedCount} package(s)`, nil)
	for _, failure in resolutionFailures do
		table.insert(combined.failures, failure)
	end
	for _, failure in result.failures do
		table.insert(combined.failures, failure)
	end
	if not result.ok then
		combined.ok = false
		combined.error = result.error or "Update failed"
		return combined
	end

	logger.info(`updateAll succeeded ({appliedCount} wally package(s), {#combined.failures} warning(s))`)
	return combined
end

local function updateAllAsync(updates: { UpdateRequest }): UpdateAllResult
	if #updates == 0 then
		return { ok = true, error = nil, failures = {} }
	end

	return runWithBusyLock(function(): UpdateAllResult
		logger.warn(`update rejected: another installer operation is in progress`)
		return {
			ok = false,
			error = "Another installer operation is in progress.",
			failures = {},
		}
	end, function(): UpdateAllResult
		return runUpdateAll(updates)
	end, function(err): UpdateAllResult
		logger.error(`updateAll crashed: {err}`)
		return {
			ok = false,
			error = `Update failed: {err}`,
			failures = { err },
		}
	end)
end

return updateAllAsync
