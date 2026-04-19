--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local applyRootsAsync = require(StudioDiscover.Source.Installer.applyRootsAsync)
local busyAtom = require(StudioDiscover.Source.Installer.busyAtom)
local createLogger = require(StudioDiscover.Source.Util.createLogger)
local lockfile = require(StudioDiscover.Source.Installer.lockfile)
local resolveAsync = require(StudioDiscover.Source.Installer.resolveAsync)
local snapshotRoots = require(StudioDiscover.Source.Installer.snapshotRoots)
local types = require(StudioDiscover.Source.Installer.types)

local logger = createLogger.createLogger("installer.update")

type Realm = "shared" | "server"
type RootRequest = types.RootRequest

export type UpdateRequest = {
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

local function findMatch(updates: { UpdateRequest }, root: RootRequest): UpdateRequest?
	for _, update in updates do
		if update.realm == root.requestRealm and update.scope == root.scope and update.name == root.name then
			return update
		end
	end
	return nil
end

-- Re-pins the version on every installed root that matches an entry in
-- `updates`, then runs a single resolve + apply cycle. One batch keeps the
-- Wally API round-trips (and the undo-stack waypoint) to a single unit of
-- work regardless of how many packages are being upgraded.
local function updateAllAsync(updates: { UpdateRequest }): UpdateAllResult
	if #updates == 0 then
		return { ok = true, error = nil, failures = {} }
	end

	if busyAtom() then
		logger.warn(`update rejected: another installer operation is in progress`)
		return {
			ok = false,
			error = "Another installer operation is in progress.",
			failures = {},
		}
	end
	busyAtom(true)

	logger.info(`updateAll starting ({#updates} package(s))`)

	local priorRoots = snapshotRoots()
	local nextRoots: { RootRequest } = {}
	local appliedCount = 0
	for _, prior in priorRoots do
		local match = findMatch(updates, prior)
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
		logger.warn("updateAll: no installed roots matched the requested updates")
		busyAtom(false)
		return {
			ok = false,
			error = "No installed packages matched the update list",
			failures = {},
		}
	end

	local lockData = lockfile.load()
	local resolved, rootAliases, resolutionFailures = resolveAsync(nextRoots, lockData, nil)
	for _, failure in resolutionFailures do
		logger.warn(`resolve failure: {failure}`)
	end

	local result = applyRootsAsync(resolved, rootAliases, `Update {appliedCount} package(s)`, nil)
	if not result.ok then
		busyAtom(false)
		return {
			ok = false,
			error = result.error or "Update failed",
			failures = resolutionFailures,
		}
	end

	local allFailures: { string } = {}
	for _, failure in resolutionFailures do
		table.insert(allFailures, failure)
	end
	for _, failure in result.failures do
		table.insert(allFailures, failure)
	end

	logger.info(`updateAll succeeded ({appliedCount} package(s), {#allFailures} warning(s))`)
	busyAtom(false)
	return {
		ok = true,
		error = nil,
		failures = allFailures,
	}
end

return updateAllAsync
