--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const asString = require(StudioDiscover.Libraries.Core.asString)
const asTable = require(StudioDiscover.Libraries.Core.asTable)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const formatPackageId = require(StudioDiscover.Libraries.PesdeRegistry.formatPackageId)
const readLockfileEntries = require(StudioDiscover.Libraries.Core.readLockfileEntries)
const splitFullName = require(StudioDiscover.Libraries.Core.splitFullName)
const targetFromRealm = require(StudioDiscover.Libraries.PesdeRegistry.targetFromRealm)
const types = require(StudioDiscover.Libraries.PesdeRegistry.types)

const function parseRealm(raw: unknown): coreTypes.Realm?
	if raw == "shared" or raw == "server" then
		return raw
	end

	return nil
end

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
		not one. An entry whose id does not match its name, version, and realm is not
		one either.
]]
const function parseEntry(raw: unknown): types.PesdeResolvedPackage?
	const entry = asTable(raw)
	if entry == nil then
		return nil
	end

	const fullName, version, realm = asString(entry.name), asString(entry.version), parseRealm(entry.realm)
	const dependencies = parseDependencies(entry.dependencies)
	if fullName == nil or version == nil or realm == nil or dependencies == nil then
		return nil
	end

	const scope, name = splitFullName(fullName)
	if scope == nil or name == nil then
		return nil
	end

	const packageId = formatPackageId(scope, name, version, targetFromRealm(realm))
	if entry.packageId ~= packageId then
		return nil
	end

	return {
		packageId = packageId,
		scope = scope,
		name = name,
		version = version,
		realm = realm,
		libPath = asString(entry.libPath),
		dependencies = dependencies,
	}
end

--[[
	Reads the `PesdeLock` ModuleScript in ServerStorage back into the graph
		`saveLockfileAsync` wrote, keyed by package id, skipping entries it cannot
		parse. A missing or unreadable lockfile reads as empty.
]]
const function loadLockfile(): { [string]: types.PesdeResolvedPackage }
	const locked: { [string]: types.PesdeResolvedPackage } = {}
	for _, entry in readLockfileEntries("PesdeLock", parseEntry) do
		locked[entry.packageId] = entry
	end

	return locked
end

return loadLockfile
