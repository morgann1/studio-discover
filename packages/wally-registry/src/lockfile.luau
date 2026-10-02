--!strict

--[[
	The `WallyLock` ModuleScript in ServerStorage: every package version currently
		resolved into the place, keyed by its `_Index` id. Resolve prefers locked
		versions, so an install does not move packages it did not have to.
]]

const ServerStorage = game:GetService("ServerStorage")

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const asString = require(StudioDiscover.Core.asString)
const asTable = require(StudioDiscover.Core.asTable)
const createLogger = require(StudioDiscover.Core.createLogger)
const packageId = require(StudioDiscover.WallyRegistry.packageId)
const replaceModuleAsync = require(StudioDiscover.Core.replaceModuleAsync)
const splitFullName = require(StudioDiscover.Core.splitFullName)
const types = require(StudioDiscover.WallyRegistry.types)

const logger = createLogger.createLogger("wally.installer.lockfile")

const LOCKFILE_NAME = "WallyLock"

-- Reads the `_Index` id of one entry the way `saveAsync` writes it, or returns nil when it is not one.
const function parseEntryId(raw: unknown): string?
	const entry = asTable(raw)
	if entry == nil then
		return nil
	end

	const fullName, version = asString(entry.name), asString(entry.version)
	if fullName == nil or version == nil then
		return nil
	end

	const scope, name = splitFullName(fullName)
	if scope == nil or name == nil then
		return nil
	end

	return packageId.format(scope, name, version)
end

--[[
	Reads which package versions are locked, as a set of `_Index` ids, skipping
		entries it cannot parse. A missing or unreadable lockfile reads as empty.
]]
const function load(): { [string]: true? }
	const lockModule = ServerStorage:FindFirstChild(LOCKFILE_NAME)
	if lockModule == nil or not lockModule:IsA("ModuleScript") then
		logger.debug("no existing lockfile; starting fresh")
		return {}
	end

	const ok, data: unknown = pcall(require, lockModule)
	const rawEntries = if ok then asTable(data) else nil
	if rawEntries == nil then
		logger.warn(`lockfile unreadable: {data}`)
		return {}
	end

	const lockedIds: { [string]: true? } = {}
	local skippedCount = 0
	local parsedCount = 0
	for _, rawEntry in rawEntries do
		const id = parseEntryId(rawEntry)
		if id == nil then
			skippedCount += 1
			continue
		end

		lockedIds[id] = true
		parsedCount += 1
	end

	if skippedCount > 0 then
		logger.warn(`skipped {skippedCount} malformed lockfile entries`)
	end
	logger.info(`loaded lockfile ({parsedCount} entries)`)
	return lockedIds
end

-- Replaces the lockfile with `resolved`. A failed write leaves no lockfile, which the next load reads as empty.
const function saveAsync(resolved: { [string]: types.ResolvedPackage })
	const sortedIds: { string } = {}
	for id in resolved do
		table.insert(sortedIds, id)
	end
	table.sort(sortedIds)

	const lines = { "return {" }
	for _, id in sortedIds do
		const entry = resolved[id]
		table.insert(lines, "\t{")
		table.insert(lines, `\t\tname = {string.format("%q", `{entry.scope}/{entry.name}`)},`)
		table.insert(lines, `\t\tversion = {string.format("%q", entry.version)},`)
		table.insert(lines, `\t\trealm = "{entry.realm}",`)

		if #entry.dependencies == 0 then
			table.insert(lines, "\t\tdependencies = {},")
		else
			table.insert(lines, "\t\tdependencies = {")
			for _, dependency in entry.dependencies do
				const alias = string.format("%q", dependency.alias)
				const dependencyId = string.format("%q", dependency.packageId)
				table.insert(lines, `\t\t\t\{ alias = {alias}, packageId = {dependencyId} },`)
			end
			table.insert(lines, "\t\t},")
		end

		table.insert(lines, "\t},")
	end
	table.insert(lines, "}")

	const err = replaceModuleAsync(ServerStorage, LOCKFILE_NAME, table.concat(lines, "\n"))
	if err ~= nil then
		logger.warn(`could not save lockfile: {err}`)
		return
	end

	logger.info(`saved lockfile ({#sortedIds} entries)`)
end

const lockfile = table.freeze({
	load = load,
	saveAsync = saveAsync,
})

return lockfile
