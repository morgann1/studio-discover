--!strict

const ServerStorage = game:GetService("ServerStorage")

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const asTable = require(StudioDiscover.Libraries.Core.asTable)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)

const logger = createLogger.createLogger("core.readLockfileEntries")

--[[
	Requires the lockfile ModuleScript named `name` in ServerStorage and returns the
		entries `parseEntry` reads, skipping the ones it returns nil for. A missing or
		unreadable lockfile has no entries, so the next resolve starts fresh.
]]
const function readLockfileEntries<T>(name: string, parseEntry: (raw: unknown) -> T?): { T }
	const lockModule = ServerStorage:FindFirstChild(name)
	if lockModule == nil or not lockModule:IsA("ModuleScript") then
		logger.debug(`no existing {name}; starting fresh`)
		return {}
	end

	const ok, data: unknown = pcall(require, lockModule)
	const rawEntries = if ok then asTable(data) else nil
	if rawEntries == nil then
		logger.warn(`{name} unreadable: {data}`)
		return {}
	end

	const entries: { T } = {}
	local skippedCount = 0
	for _, rawEntry in rawEntries do
		const entry = parseEntry(rawEntry)
		if entry == nil then
			skippedCount += 1
			continue
		end

		table.insert(entries, entry)
	end

	if skippedCount > 0 then
		logger.warn(`skipped {skippedCount} malformed {name} entries`)
	end
	logger.info(`loaded {name} ({#entries} entries)`)
	return entries
end

return readLockfileEntries
