--!strict

const ServerStorage = game:GetService("ServerStorage")

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const replaceModuleAsync = require(StudioDiscover.Libraries.Core.replaceModuleAsync)
const types = require(StudioDiscover.Libraries.PesdeRegistry.types)

const logger = createLogger.createLogger("pesde.installer.lockfile")

--[[
	Replaces the `PesdeLock` ModuleScript in ServerStorage with `resolved`: every
		package version currently resolved into the place, keyed by its pesde package
		id. A failed write leaves no lockfile.
]]
const function saveLockfileAsync(resolved: { [string]: types.PesdeResolvedPackage })
	const sortedIds: { string } = {}
	for id in resolved do
		table.insert(sortedIds, id)
	end
	table.sort(sortedIds)

	const lines = { "return {" }
	for _, id in sortedIds do
		const pkg = resolved[id]
		table.insert(lines, "\t{")
		table.insert(lines, `\t\tpackageId = {string.format("%q", id)},`)
		table.insert(lines, `\t\tname = {string.format("%q", `{pkg.scope}/{pkg.name}`)},`)
		table.insert(lines, `\t\tversion = {string.format("%q", pkg.version)},`)
		table.insert(lines, `\t\trealm = "{pkg.realm}",`)

		if pkg.libPath ~= nil then
			table.insert(lines, `\t\tlibPath = {string.format("%q", pkg.libPath)},`)
		end

		if #pkg.dependencies == 0 then
			table.insert(lines, "\t\tdependencies = {},")
		else
			table.insert(lines, "\t\tdependencies = {")
			for _, dependency in pkg.dependencies do
				const alias = string.format("%q", dependency.alias)
				const dependencyId = string.format("%q", dependency.packageId)
				table.insert(lines, `\t\t\t\{ alias = {alias}, packageId = {dependencyId} },`)
			end
			table.insert(lines, "\t\t},")
		end

		table.insert(lines, "\t},")
	end
	table.insert(lines, "}")

	const err = replaceModuleAsync(ServerStorage, "PesdeLock", table.concat(lines, "\n"))
	if err ~= nil then
		logger.warn(`could not save lockfile: {err}`)
		return
	end

	logger.info(`saved lockfile ({#sortedIds} entries)`)
end

return saveLockfileAsync
