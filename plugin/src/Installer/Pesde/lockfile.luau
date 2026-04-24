--!strict

local ServerStorage = game:GetService("ServerStorage")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local createLogger = require(StudioDiscover.Source.Util.createLogger)
local packageId = require(StudioDiscover.Source.Installer.Pesde.packageId)
local setScriptSource = require(StudioDiscover.Source.Util.setScriptSource)
local types = require(StudioDiscover.Source.Installer.Pesde.types)

local logger = createLogger.createLogger("installer.pesdeLockfile")

type PesdeResolvedPackage = types.PesdeResolvedPackage
type Realm = types.Realm
type Kind = types.Kind

export type LockDependency = {
	alias: string,
	packageId: string,
}

export type LockEntry = {
	name: string,
	version: string,
	realm: Realm,
	kind: Kind,
	libPath: string?,
	dependencies: { LockDependency },
}

local LOCKFILE_NAME = "PesdeLock"

local function escapeString(value: string): string
	local escaped = string.gsub(value, "\\", "\\\\")
	escaped = string.gsub(escaped, '"', '\\"')
	return escaped
end

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
		local scope, name, version, target = packageId.parse(entry.packageId or "")
		if scope == nil or name == nil or version == nil or target == nil then
			logger.warn(`lockfile entry has unparseable packageId: "{entry.packageId}"`)
			continue
		end
		entries[entry.packageId] = {
			name = entry.name,
			version = entry.version,
			realm = entry.realm or "shared",
			kind = entry.kind or "pesde",
			libPath = entry.libPath,
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

local function save(resolved: { [string]: PesdeResolvedPackage })
	local lines: { string } = { "return {" }

	local sortedIds: { string } = {}
	for id in resolved do
		table.insert(sortedIds, id)
	end
	table.sort(sortedIds)

	for _, id in sortedIds do
		local pkg = resolved[id]
		table.insert(lines, "\t{")
		table.insert(lines, `\t\tpackageId = "{escapeString(id)}",`)
		table.insert(lines, `\t\tname = "{escapeString(pkg.scope)}/{escapeString(pkg.name)}",`)
		table.insert(lines, `\t\tversion = "{escapeString(pkg.version)}",`)
		table.insert(lines, `\t\trealm = "{pkg.realm}",`)
		table.insert(lines, `\t\tkind = "{pkg.kind}",`)
		if pkg.libPath ~= nil then
			table.insert(lines, `\t\tlibPath = "{escapeString(pkg.libPath)}",`)
		end
		if #pkg.dependencies > 0 then
			table.insert(lines, "\t\tdependencies = {")
			for _, dep in pkg.dependencies do
				table.insert(
					lines,
					`\t\t\t\{ alias = "{escapeString(dep.alias)}", packageId = "{escapeString(dep.packageId)}" },`
				)
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
	lockModule.Parent = ServerStorage
	local ok, err = setScriptSource(lockModule, table.concat(lines, "\n"))
	if not ok then
		logger.warn(`could not save lockfile: {err}`)
		lockModule:Destroy()
		return
	end
	logger.info(`saved lockfile ({#sortedIds} entries)`)
end

return table.freeze({
	load = load,
	save = save,
})
