--!strict

local ServerStorage = game:GetService("ServerStorage")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local createLogger = require(StudioDiscover.Source.Util.createLogger)

local packageId = require(StudioDiscover.Source.Installer.packageId)
local types = require(StudioDiscover.Source.Installer.types)

local logger = createLogger.createLogger("installer.lockfile")

type LockEntry = types.LockEntry
type ResolvedPackage = types.ResolvedPackage

local LOCKFILE_NAME = "WallyLock"

local function load(): { [string]: LockEntry }
	local lockModule = ServerStorage:FindFirstChild(LOCKFILE_NAME)
	if lockModule == nil or not lockModule:IsA("ModuleScript") then
		logger.debug("no existing lockfile; starting fresh")
		return {}
	end
	local ok, data = pcall(require, lockModule :: any)
	if not ok or typeof(data) ~= "table" then
		logger.warn(`lockfile unreadable: {data}`)
		return {}
	end
	local entries: { [string]: LockEntry } = {}
	for _, entry in data :: any do
		local scope, name = entry.name:match("^(.+)/(.+)$")
		if scope == nil or name == nil then
			logger.warn(`lockfile entry has unparseable name: "{entry.name}"`)
			continue
		end
		local id = packageId.format(scope, name, entry.version)
		entries[id] = {
			name = entry.name,
			version = entry.version,
			realm = entry.realm or "shared",
			dependencies = entry.dependencies or {},
		}
	end
	local parsedCount = 0
	for _ in entries do
		parsedCount += 1
	end
	logger.info(`loaded lockfile ({#data} entries, {parsedCount} parsed)`)
	return entries
end

local function save(resolved: { [string]: ResolvedPackage })
	local lines: { string } = { "return {" }

	local sortedIds: { string } = {}
	for id in resolved do
		table.insert(sortedIds, id)
	end
	table.sort(sortedIds)

	for _, id in sortedIds do
		local entry = resolved[id]
		table.insert(lines, "\t{")
		table.insert(lines, `\t\tname = "{entry.scope}/{entry.name}",`)
		table.insert(lines, `\t\tversion = "{entry.version}",`)
		table.insert(lines, `\t\trealm = "{entry.realm}",`)
		if #entry.dependencies > 0 then
			table.insert(lines, "\t\tdependencies = {")
			for _, dep in entry.dependencies do
				local depLine = '\t\t\t{ alias = "' .. dep.alias .. '", packageId = "' .. dep.packageId .. '" },'
				table.insert(lines, depLine)
			end
			table.insert(lines, "\t\t},")
		else
			table.insert(lines, "\t\tdependencies = {},")
		end
		table.insert(lines, "\t},")
	end
	table.insert(lines, "}")

	local existing = ServerStorage:FindFirstChild(LOCKFILE_NAME)
	if existing ~= nil then
		existing:Destroy()
	end
	local lockModule = Instance.new("ModuleScript")
	lockModule.Name = LOCKFILE_NAME
	lockModule.Source = table.concat(lines, "\n")
	lockModule.Parent = ServerStorage
	logger.info(`saved lockfile ({#sortedIds} entries)`)
end

return table.freeze({
	load = load,
	save = save,
})
