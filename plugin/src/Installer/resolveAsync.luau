--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local getPackageMetadataAsync = require(StudioDiscover.Source.Api.Wally.getMetadataAsync)

local isDependencyValid = require(StudioDiscover.Source.Installer.isDependencyValid)
local packageId = require(StudioDiscover.Source.Installer.packageId)
local promoteRealm = require(StudioDiscover.Source.Installer.promoteRealm)
local semver = require(StudioDiscover.Source.Installer.semver)
local types = require(StudioDiscover.Source.Installer.types)

local compareSemver = require(StudioDiscover.Source.Util.compareSemver)
local createLogger = require(StudioDiscover.Source.Util.createLogger)
local parseSemver = require(StudioDiscover.Source.Util.parseSemver)

local logger = createLogger.createLogger("installer.resolve")

type ResolvedPackage = types.ResolvedPackage
type RootRequest = types.RootRequest
type LockEntry = types.LockEntry
type Realm = "shared" | "server"
type ProgressCallback = types.ProgressCallback
type Semver = parseSemver.Semver

type ActivatedEntry = {
	scope: string,
	name: string,
	version: string,
	semver: Semver,
	realm: Realm,
	packageId: string,
}

type DependencyRequest = {
	scope: string,
	name: string,
	constraints: string,
	requestRealm: Realm,
	originRealm: Realm,
	requestedBy: string,
	alias: string,
}

-- Walks the Wally metadata graph breadth-first from a set of root requests
-- and produces a fully-resolved package map. Mirrors Wally's resolver: reuse
-- already-activated versions that satisfy the constraint, semver-compatibility
-- conflicts bail out, realm promotion climbs toward `shared`, and candidates
-- are sorted with lockfile-known versions first.
local function resolveAsync(
	roots: { RootRequest },
	lockfile: { [string]: LockEntry },
	onProgress: ProgressCallback?
): ({ [string]: ResolvedPackage }, { [string]: string }, { string })
	local resolved: { [string]: ResolvedPackage } = {}
	local rootAliases: { [string]: string } = {}
	local failures: { string } = {}

	local activated: { [string]: ActivatedEntry } = {}
	local activatedByName: { [string]: { ActivatedEntry } } = {}

	local queue: { DependencyRequest } = {}

	local function activate(scope: string, name: string, version: string, pkgRealm: Realm, pkgId: string)
		local sv = parseSemver(version)
		if sv == nil then
			return
		end
		local entry: ActivatedEntry = {
			scope = scope,
			name = name,
			version = version,
			semver = sv,
			realm = pkgRealm,
			packageId = pkgId,
		}
		activated[pkgId] = entry
		local fullName = `{scope}/{name}`
		if activatedByName[fullName] == nil then
			activatedByName[fullName] = {}
		end
		table.insert(activatedByName[fullName], entry)
	end

	for _, root in roots do
		local rootRealm: Realm = root.requestRealm
		local rootPackageId = packageId.format(root.scope, root.name, root.version)

		logger.info(`root {root.scope}/{root.name}@{root.version} realm={rootRealm} alias={root.alias}`)

		if onProgress ~= nil then
			onProgress(`Resolving {root.scope}/{root.name}@{root.version}...`)
		end

		local rootMeta = getPackageMetadataAsync(root.scope, root.name)
		if rootMeta == nil or rootMeta.versions == nil then
			logger.warn(`metadata unavailable for {root.scope}/{root.name}`)
			table.insert(failures, `{root.scope}/{root.name}: metadata unavailable`)
			continue
		end

		local rootVersionData = nil
		for _, versionData in rootMeta.versions do
			if versionData.package.version == root.version then
				rootVersionData = versionData
				break
			end
		end
		if rootVersionData == nil then
			logger.warn(`version {root.version} not found in metadata for {root.scope}/{root.name}`)
			table.insert(failures, `{root.scope}/{root.name}@{root.version}: version not found`)
			continue
		end

		local rootPackageRealm = rootVersionData.package.realm
		if rootPackageRealm ~= nil and rootPackageRealm ~= "dev" then
			rootRealm = promoteRealm(rootRealm, rootPackageRealm :: Realm)
		end

		activate(root.scope, root.name, root.version, rootRealm, rootPackageId)
		rootAliases[rootPackageId] = root.alias

		resolved[rootPackageId] = {
			scope = root.scope,
			name = root.name,
			version = root.version,
			realm = rootRealm,
			packageId = rootPackageId,
			dependencies = {},
		}

		local depSources: { { deps: { [string]: string }, requestRealm: Realm } } = {}
		if rootVersionData.dependencies ~= nil then
			table.insert(depSources, { deps = rootVersionData.dependencies, requestRealm = "shared" })
		end
		if rootVersionData["server-dependencies"] ~= nil then
			table.insert(depSources, { deps = rootVersionData["server-dependencies"], requestRealm = "server" })
		end

		for _, source in depSources do
			for depAlias, depValue in source.deps do
				local depPath, depConstraints = depValue:match("^([^@]+)@(.+)$")
				if depPath == nil or depConstraints == nil then
					logger.warn(`could not parse root dep "{depValue}" (alias={depAlias})`)
					table.insert(failures, `{depAlias}: could not parse "{depValue}"`)
					continue
				end
				local depScope, depName = depPath:match("^(.+)/(.+)$")
				if depScope == nil or depName == nil then
					logger.warn(`could not parse root dep path "{depPath}" (alias={depAlias})`)
					table.insert(failures, `{depAlias}: could not parse "{depValue}"`)
					continue
				end
				logger.debug(
					`queued {depScope}/{depName}@{depConstraints} (alias={depAlias}, realm={source.requestRealm})`
				)
				table.insert(queue, {
					scope = depScope :: string,
					name = depName :: string,
					constraints = depConstraints :: string,
					requestRealm = source.requestRealm,
					originRealm = source.requestRealm,
					requestedBy = rootPackageId,
					alias = depAlias,
				})
			end
		end
	end

	while #queue > 0 do
		local request = table.remove(queue, 1) :: DependencyRequest
		local fullName = `{request.scope}/{request.name}`
		local satisfies = semver.buildSatisfies(request.constraints)

		logger.debug(
			`visit {fullName}@{request.constraints} (requestedBy={request.requestedBy}, realm={request.requestRealm})`
		)

		-- Reuse an already-activated match, promoting its realm if needed.
		local existingMatches = activatedByName[fullName]
		local reused = false
		if existingMatches ~= nil then
			for _, entry in existingMatches do
				if satisfies(entry.version) then
					local promoted: Realm = promoteRealm(entry.realm, request.originRealm)
					if promoted ~= entry.realm then
						logger.debug(`promote realm for {entry.packageId}: {entry.realm} -> {promoted}`)
						entry.realm = promoted
						local resolvedEntry = resolved[entry.packageId]
						if resolvedEntry ~= nil then
							resolvedEntry.realm = promoted
						end
					end

					local parentResolved = resolved[request.requestedBy]
					if parentResolved ~= nil then
						local dep: types.Dependency = {
							alias = request.alias,
							packageId = entry.packageId,
							realm = promoted,
						}
						table.insert(parentResolved.dependencies, dep)
					end
					reused = true
					logger.debug(`reused {entry.packageId} for {fullName}@{request.constraints}`)
					break
				end
			end
		end
		if reused then
			continue
		end

		if onProgress ~= nil then
			onProgress(`Resolving {fullName}...`)
		end

		local meta = getPackageMetadataAsync(request.scope, request.name)
		if meta == nil or meta.versions == nil then
			logger.warn(`metadata unavailable for {fullName}`)
			table.insert(failures, `{fullName}: metadata unavailable`)
			continue
		end

		-- Filter to candidates matching the constraint, then sort lockfile-
		-- known first and descending by version.
		local candidates = {}
		for _, versionData in meta.versions do
			if satisfies(versionData.package.version) then
				table.insert(candidates, versionData)
			end
		end
		logger.debug(`{#candidates} of {#meta.versions} candidate(s) match "{request.constraints}"`)

		table.sort(candidates, function(a, b)
			local aId = packageId.format(request.scope, request.name, a.package.version)
			local bId = packageId.format(request.scope, request.name, b.package.version)
			local aLocked = lockfile[aId] ~= nil
			local bLocked = lockfile[bId] ~= nil
			if aLocked ~= bLocked then
				return aLocked
			end
			local aSv = parseSemver(a.package.version)
			local bSv = parseSemver(b.package.version)
			if aSv ~= nil and bSv ~= nil then
				return compareSemver(aSv, bSv) > 0
			end
			return false
		end)

		local chosen = nil
		for _, candidate in candidates do
			local candidateRealm: Realm = if candidate.package.realm == "server" then "server" else "shared"
			if not isDependencyValid(request.requestRealm, candidateRealm) then
				continue
			end

			local candidateSv = parseSemver(candidate.package.version)
			if candidateSv == nil then
				continue
			end

			local hasConflict = false
			if existingMatches ~= nil then
				for _, entry in existingMatches do
					if semver.compatible(candidateSv, entry.semver) then
						hasConflict = true
						break
					end
				end
			end
			if hasConflict then
				continue
			end

			chosen = candidate
			break
		end

		if chosen == nil then
			logger.warn(`no compatible version for {fullName}@{request.constraints}`)
			table.insert(failures, `{fullName}: no compatible version for "{request.constraints}"`)
			continue
		end

		local chosenVersion = chosen.package.version
		local chosenPackageRealm: Realm = if chosen.package.realm == "server" then "server" else "shared"
		local chosenRealm: Realm = promoteRealm(chosenPackageRealm, request.originRealm)
		local chosenPackageId = packageId.format(request.scope, request.name, chosenVersion)

		logger.debug(`chose {fullName}@{chosenVersion} (realm={chosenRealm})`)

		activate(request.scope, request.name, chosenVersion, chosenRealm, chosenPackageId)

		local newResolved: ResolvedPackage = {
			scope = request.scope,
			name = request.name,
			version = chosenVersion,
			realm = chosenRealm,
			packageId = chosenPackageId,
			dependencies = {},
		}
		resolved[chosenPackageId] = newResolved

		local parentResolved = resolved[request.requestedBy]
		if parentResolved ~= nil then
			local dep: types.Dependency = {
				alias = request.alias,
				packageId = chosenPackageId,
				realm = chosenRealm,
			}
			table.insert(parentResolved.dependencies, dep)
		end

		local chosenDepSources: { { deps: { [string]: string }, requestRealm: Realm } } = {}
		if chosen.dependencies ~= nil then
			table.insert(chosenDepSources, { deps = chosen.dependencies, requestRealm = "shared" })
		end
		if chosen["server-dependencies"] ~= nil then
			table.insert(chosenDepSources, { deps = chosen["server-dependencies"], requestRealm = "server" })
		end

		for _, source in chosenDepSources do
			for depAlias, depValue in source.deps do
				local depPath, depConstraints = depValue:match("^([^@]+)@(.+)$")
				if depPath == nil or depConstraints == nil then
					table.insert(failures, `{depAlias}: could not parse "{depValue}"`)
					continue
				end
				local depScope, depName = depPath:match("^(.+)/(.+)$")
				if depScope == nil or depName == nil then
					table.insert(failures, `{depAlias}: could not parse "{depValue}"`)
					continue
				end
				table.insert(queue, {
					scope = depScope :: string,
					name = depName :: string,
					constraints = depConstraints :: string,
					requestRealm = source.requestRealm,
					originRealm = promoteRealm(source.requestRealm, chosenRealm),
					requestedBy = chosenPackageId,
					alias = depAlias,
				})
			end
		end
	end

	return resolved, rootAliases, failures
end

return resolveAsync
