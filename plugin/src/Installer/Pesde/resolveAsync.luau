--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local compareSemver = require(StudioDiscover.Source.Util.compareSemver)
local createLogger = require(StudioDiscover.Source.Util.createLogger)
local parseSemver = require(StudioDiscover.Source.Util.parseSemver)

local fetchMetadataAsync = require(StudioDiscover.Source.Installer.Pesde.fetchMetadataAsync)
local packageId = require(StudioDiscover.Source.Installer.Pesde.packageId)
local pesdeSemver = require(StudioDiscover.Source.Installer.Pesde.semver)
local types = require(StudioDiscover.Source.Installer.Pesde.types)

local logger = createLogger.createLogger("installer.pesdeResolve")

type Realm = types.Realm
type Kind = types.Kind
type PesdeResolvedPackage = types.PesdeResolvedPackage
type PesdeDependency = types.PesdeDependency
type ProgressCallback = types.ProgressCallback

export type RootRequest = {
	scope: string,
	name: string,
	version: string,
	realm: Realm,
	alias: string,
}

type DepRequest = {
	parentId: string,
	alias: string,
	scope: string,
	name: string,
	versionReq: string,
	target: "roblox" | "roblox_server",
}

local function targetFromRealm(realm: Realm): "roblox" | "roblox_server"
	return if realm == "server" then "roblox_server" else "roblox"
end

local function realmFromTarget(target: string): Realm
	return if target == "roblox_server" then "server" else "shared"
end

local function findVersion(
	metadata: fetchMetadataAsync.PesdeMetadata,
	target: "roblox" | "roblox_server",
	exactVersion: string?
): fetchMetadataAsync.VersionEntry?
	if exactVersion == nil then
		return nil
	end
	for _, entry in metadata.versions do
		if entry.target == target and entry.version == exactVersion then
			return entry
		end
	end
	return nil
end

local function pickMatchingVersion(
	metadata: fetchMetadataAsync.PesdeMetadata,
	target: "roblox" | "roblox_server",
	versionReq: string
): fetchMetadataAsync.VersionEntry?
	local satisfies = pesdeSemver.buildSatisfies(versionReq)
	local candidates: { fetchMetadataAsync.VersionEntry } = {}
	for _, entry in metadata.versions do
		if entry.target == target and satisfies(entry.version) then
			table.insert(candidates, entry)
		end
	end
	if #candidates == 0 then
		return nil
	end
	table.sort(candidates, function(a, b)
		local aSv = parseSemver(a.version)
		local bSv = parseSemver(b.version)
		if aSv ~= nil and bSv ~= nil then
			return compareSemver(aSv, bSv) > 0
		end
		return a.version > b.version
	end)
	return candidates[1]
end

local function resolveAsync(
	roots: { RootRequest },
	onProgress: ProgressCallback?
): ({ [string]: PesdeResolvedPackage }, { [string]: string }, { string })
	local resolved: { [string]: PesdeResolvedPackage } = {}
	local rootAliases: { [string]: string } = {}
	local failures: { string } = {}

	local activatedByName: { [string]: { PesdeResolvedPackage } } = {}

	local function activate(pkg: PesdeResolvedPackage)
		resolved[pkg.packageId] = pkg
		local key = `{pkg.scope}/{pkg.name}`
		if activatedByName[key] == nil then
			activatedByName[key] = {}
		end
		table.insert(activatedByName[key], pkg)
	end

	local queue: { DepRequest } = {}

	for _, root in roots do
		local target: "roblox" | "roblox_server" = targetFromRealm(root.realm)
		if onProgress ~= nil then
			onProgress(`Resolving {root.scope}/{root.name}@{root.version}...`)
		end

		local metadata, err = fetchMetadataAsync(root.scope, root.name)
		if metadata == nil then
			table.insert(failures, `{root.scope}/{root.name}: {err}`)
			continue
		end

		local entry = findVersion(metadata, target, root.version)
		if entry == nil then
			table.insert(failures, `{root.scope}/{root.name}@{root.version}: version not found for target {target}`)
			continue
		end

		local pkgId = packageId.format(root.scope, root.name, root.version, target)
		local pkg: PesdeResolvedPackage = {
			packageId = pkgId,
			scope = root.scope,
			name = root.name,
			version = root.version,
			realm = root.realm,
			kind = "pesde",
			libPath = entry.libPath,
			dependencies = {},
		}
		activate(pkg)
		rootAliases[pkgId] = root.alias

		for _, dep in entry.dependencies do
			if dep.ty == "dev" then
				continue
			end
			local depScope, depName = dep.name:match("^(.+)/(.+)$")
			if depScope == nil or depName == nil then
				table.insert(failures, `{dep.alias}: could not parse "{dep.name}"`)
				continue
			end
			if dep.kind == "wally" then
				table.insert(failures, `{dep.alias}: wally-proxied dep "{dep.name}" not yet supported`)
				continue
			end
			local depTarget: "roblox" | "roblox_server" = (dep.target or target) :: any
			table.insert(queue, {
				parentId = pkgId,
				alias = dep.alias,
				scope = depScope :: string,
				name = depName :: string,
				versionReq = dep.versionReq,
				target = depTarget,
			})
		end
	end

	while #queue > 0 do
		local req = table.remove(queue, 1) :: DepRequest
		local fullName = `{req.scope}/{req.name}`

		local existingMatches = activatedByName[fullName]
		local reused: PesdeResolvedPackage? = nil
		if existingMatches ~= nil then
			local satisfies = pesdeSemver.buildSatisfies(req.versionReq)
			for _, pkg in existingMatches do
				if pkg.realm == realmFromTarget(req.target) and satisfies(pkg.version) then
					reused = pkg
					break
				end
			end
		end

		local chosen: PesdeResolvedPackage? = reused
		if chosen == nil then
			if onProgress ~= nil then
				onProgress(`Resolving {fullName}...`)
			end

			local metadata, err = fetchMetadataAsync(req.scope, req.name)
			if metadata == nil then
				table.insert(failures, `{fullName}: {err}`)
				continue
			end

			local entry = pickMatchingVersion(metadata, req.target, req.versionReq)
			if entry == nil then
				table.insert(failures, `{fullName}: no version matches "{req.versionReq}" for target {req.target}`)
				continue
			end

			local realm: Realm = realmFromTarget(entry.target)
			local pkgId = packageId.format(req.scope, req.name, entry.version, entry.target)
			local pkg: PesdeResolvedPackage = {
				packageId = pkgId,
				scope = req.scope,
				name = req.name,
				version = entry.version,
				realm = realm,
				kind = "pesde",
				libPath = entry.libPath,
				dependencies = {},
			}
			activate(pkg)
			logger.debug(`resolved {pkgId}`)

			for _, dep in entry.dependencies do
				if dep.ty == "dev" or dep.ty == "peer" then
					continue
				end
				local depScope, depName = dep.name:match("^(.+)/(.+)$")
				if depScope == nil or depName == nil then
					table.insert(failures, `{dep.alias}: could not parse "{dep.name}"`)
					continue
				end
				if dep.kind == "wally" then
					table.insert(failures, `{dep.alias}: wally-proxied dep "{dep.name}" not yet supported`)
					continue
				end
				local depTarget: "roblox" | "roblox_server" = dep.target or entry.target
				table.insert(queue, {
					parentId = pkgId,
					alias = dep.alias,
					scope = depScope :: string,
					name = depName :: string,
					versionReq = dep.versionReq,
					target = depTarget,
				})
			end

			chosen = pkg
		end

		local parent = resolved[req.parentId]
		if parent ~= nil and chosen ~= nil then
			table.insert(parent.dependencies, {
				alias = req.alias,
				packageId = chosen.packageId,
			})
		end
	end

	return resolved, rootAliases, failures
end

return resolveAsync
