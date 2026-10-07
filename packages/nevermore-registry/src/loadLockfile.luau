--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const asString = require(StudioDiscover.Libraries.Core.asString)
const asTable = require(StudioDiscover.Libraries.Core.asTable)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const formatPackageId = require(StudioDiscover.Libraries.NevermoreRegistry.formatPackageId)
const readLockfileEntries = require(StudioDiscover.Libraries.Core.readLockfileEntries)
const types = require(StudioDiscover.Libraries.NevermoreRegistry.types)

-- Reads every edge of one entry, or returns nil when any of them is malformed.
const function parseDependencies(raw: unknown): { coreTypes.Dependency }?
	const rawDependencies = asTable(raw)
	if rawDependencies == nil then
		return nil
	end

	const dependencies: { coreTypes.Dependency } = {}
	for _, rawDependency in rawDependencies do
		const dependency = asTable(rawDependency)
		if dependency == nil then
			return nil
		end

		const alias, packageId = asString(dependency.alias), asString(dependency.packageId)
		if alias == nil or packageId == nil then
			return nil
		end

		table.insert(dependencies, { alias = alias, packageId = packageId })
	end

	return dependencies
end

--[[
	Reads one entry the way `saveLockfileAsync` writes it, or returns nil when it is
		not one. An entry whose id does not match its name and version is not one
		either.
]]
const function parseEntry(raw: unknown): types.NevermoreResolvedPackage?
	const entry = asTable(raw)
	if entry == nil then
		return nil
	end

	const name, version = asString(entry.name), asString(entry.version)
	const dependencies = parseDependencies(entry.dependencies)
	if name == nil or version == nil or dependencies == nil then
		return nil
	end

	const packageId = formatPackageId(name, version)
	if entry.packageId ~= packageId then
		return nil
	end

	return {
		packageId = packageId,
		name = name,
		version = version,
		dependencies = dependencies,
	}
end

--[[
	Reads the `NevermoreLock` ModuleScript in ServerStorage back into the graph
		`saveLockfileAsync` wrote, keyed by package id, skipping entries it cannot
		parse. A missing or unreadable lockfile reads as empty.
]]
const function loadLockfile(): { [string]: types.NevermoreResolvedPackage }
	const locked: { [string]: types.NevermoreResolvedPackage } = {}
	for _, entry in readLockfileEntries("NevermoreLock", parseEntry) do
		locked[entry.packageId] = entry
	end

	return locked
end

return loadLockfile
