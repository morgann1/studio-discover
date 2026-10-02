--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const coreTypes = require(StudioDiscover.Libraries.Core.types)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const getMetadataAsync = require(StudioDiscover.Libraries.WallyRegistry.Api.getMetadataAsync)
const isDependencyValid = require(StudioDiscover.Libraries.WallyRegistry.isDependencyValid)
const isNewerVersion = require(StudioDiscover.Libraries.Semver.isNewerVersion)
const packageId = require(StudioDiscover.Libraries.WallyRegistry.packageId)
const parseSemver = require(StudioDiscover.Libraries.Semver.parseSemver)
const promoteRealm = require(StudioDiscover.Libraries.WallyRegistry.promoteRealm)
const splitFullName = require(StudioDiscover.Libraries.Core.splitFullName)
const types = require(StudioDiscover.Libraries.WallyRegistry.types)
const wallySemver = require(StudioDiscover.Libraries.Semver.wally)

const logger = createLogger.createLogger("wally.installer.resolve")

type Realm = coreTypes.Realm
type PackageVersion = coreTypes.PackageVersion
type ResolvedPackage = types.ResolvedPackage

-- A version already in the graph, which a later request reuses when it satisfies it.
type Activated = {
	read resolved: ResolvedPackage,
	read semver: parseSemver.Semver,
}

type DependencyRequest = {
	read scope: string,
	read name: string,
	read constraints: string,
	read requestRealm: Realm,
	read originRealm: Realm,
	read requestedBy: string,
	read alias: string,
}

const function findVersion(metadata: coreTypes.PackageMetadata, version: string): PackageVersion?
	for _, versionData in metadata.versions do
		if versionData.package.version == version then
			return versionData
		end
	end

	return nil
end

const function packageRealm(versionData: PackageVersion): Realm
	return if versionData.package.realm == "server" then "server" else "shared"
end

--[[
	Reads the dependency requests out of one version's manifest, along with the
		entries it could not parse.

	A root's dependencies are requested from the realm their section names. Below
		the roots, a shared parent pulls its dependencies into shared as well, so
		`parentRealm` is nil for a root.
]]
const function readDependencies(
	versionData: PackageVersion,
	requestedBy: string,
	parentRealm: Realm?
): ({ DependencyRequest }, { string })
	const requests: { DependencyRequest } = {}
	const failures: { string } = {}

	const function readSection(dependencies: coreTypes.DependencyMap, requestRealm: Realm)
		for alias, value in dependencies do
			const path, constraints = value:match("^([^@]+)@(.+)$")
			const scope, name = splitFullName(path or "")
			if scope == nil or name == nil or constraints == nil then
				logger.warn(`could not parse dependency "{value}" (alias={alias})`)
				table.insert(failures, `{alias}: could not parse "{value}"`)
				continue
			end

			logger.debug(`queued {scope}/{name}@{constraints} (alias={alias}, realm={requestRealm})`)
			table.insert(requests, {
				scope = scope,
				name = name,
				constraints = constraints,
				requestRealm = requestRealm,
				originRealm = promoteRealm(requestRealm, parentRealm or requestRealm),
				requestedBy = requestedBy,
				alias = alias,
			})
		end
	end

	readSection(versionData.dependencies, "shared")
	readSection(versionData["server-dependencies"], "server")

	return requests, failures
end

--[[
	Resolves `roots` and everything they depend on against Wally's registry.

	Returns the graph keyed by `_Index` id, each root's alias keyed the same way, the
		failures along the way, and the roots it could not resolve at all. Applying
		without those roots would uninstall them, so callers stop instead.

	Versions in `lockedIds` win over newer ones, so an install only moves what it
		has to. Two versions of a package coexist only when they are
		semver-incompatible, as in wally.
]]
const function resolveAsync(
	roots: { coreTypes.RootRequest },
	lockedIds: { [string]: true? },
	onProgress: coreTypes.ProgressCallback?
): (
	{ [string]: ResolvedPackage },
	{ [string]: string },
	{ string },
	{ coreTypes.RootRequest }
)
	const resolved: { [string]: ResolvedPackage } = {}
	const rootAliases: { [string]: string } = {}
	const failures: { string } = {}
	const unresolvedRoots: { coreTypes.RootRequest } = {}
	const activatedByName: { [string]: { Activated }? } = {}
	const queue: { DependencyRequest } = {}

	const function activate(resolvedPackage: ResolvedPackage)
		resolved[resolvedPackage.packageId] = resolvedPackage

		const semver = parseSemver(resolvedPackage.version)
		if semver == nil then
			return
		end

		const fullName = `{resolvedPackage.scope}/{resolvedPackage.name}`
		const activated = activatedByName[fullName] or {}
		table.insert(activated, { resolved = resolvedPackage, semver = semver })
		activatedByName[fullName] = activated
	end

	const function enqueueDependencies(versionData: PackageVersion, requestedBy: string, parentRealm: Realm?)
		const requests, readFailures = readDependencies(versionData, requestedBy, parentRealm)
		table.move(requests, 1, #requests, #queue + 1, queue)
		table.move(readFailures, 1, #readFailures, #failures + 1, failures)
	end

	const function addEdge(request: DependencyRequest, dependencyId: string)
		const parent = resolved[request.requestedBy]
		if parent ~= nil then
			table.insert(parent.dependencies, { alias = request.alias, packageId = dependencyId })
		end
	end

	for _, root in roots do
		const rootPackageId = packageId.format(root.scope, root.name, root.version)
		logger.info(`root {root.scope}/{root.name}@{root.version} realm={root.requestRealm} alias={root.alias}`)

		if onProgress ~= nil then
			onProgress(`Resolving {root.scope}/{root.name}@{root.version}...`)
		end

		const metadata, err = getMetadataAsync(root.scope, root.name)
		if metadata == nil then
			logger.warn(`metadata unavailable for {root.scope}/{root.name}: {err}`)
			table.insert(failures, `{root.scope}/{root.name}: {err}`)
			table.insert(unresolvedRoots, root)
			continue
		end

		const versionData = findVersion(metadata, root.version)
		if versionData == nil then
			logger.warn(`version {root.version} not found in metadata for {root.scope}/{root.name}`)
			table.insert(failures, `{root.scope}/{root.name}@{root.version}: version not found`)
			table.insert(unresolvedRoots, root)
			continue
		end

		-- A root lands where the user asked, unless its manifest says it has to be shared.
		const manifestRealm = versionData.package.realm
		const realm = if manifestRealm == "shared" or manifestRealm == "server"
			then promoteRealm(root.requestRealm, manifestRealm)
			else root.requestRealm

		activate({
			scope = root.scope,
			name = root.name,
			version = root.version,
			realm = realm,
			packageId = rootPackageId,
			dependencies = {},
		})
		rootAliases[rootPackageId] = root.alias
		enqueueDependencies(versionData, rootPackageId, nil)
	end

	local head = 1
	while head <= #queue do
		const request = queue[head]
		head += 1

		const fullName = `{request.scope}/{request.name}`
		const satisfies = wallySemver.buildSatisfies(request.constraints)
		if satisfies == nil then
			logger.warn(`could not parse constraint for {fullName}@{request.constraints}`)
			table.insert(failures, `{fullName}: could not parse constraint "{request.constraints}"`)
			continue
		end

		logger.debug(
			`visit {fullName}@{request.constraints} (requestedBy={request.requestedBy}, realm={request.requestRealm})`
		)

		const activated = activatedByName[fullName] or {}

		local reused: ResolvedPackage? = nil
		for _, entry in activated do
			if satisfies(entry.resolved.version) then
				reused = entry.resolved
				break
			end
		end

		if reused ~= nil then
			const promoted = promoteRealm(reused.realm, request.originRealm)
			if promoted ~= reused.realm then
				logger.debug(`promote realm for {reused.packageId}: {reused.realm} -> {promoted}`)
				reused.realm = promoted
			end

			addEdge(request, reused.packageId)
			logger.debug(`reused {reused.packageId} for {fullName}@{request.constraints}`)
			continue
		end

		if onProgress ~= nil then
			onProgress(`Resolving {fullName}...`)
		end

		const metadata, err = getMetadataAsync(request.scope, request.name)
		if metadata == nil then
			logger.warn(`metadata unavailable for {fullName}: {err}`)
			table.insert(failures, `{fullName}: {err}`)
			continue
		end

		const candidates: { PackageVersion } = {}
		for _, versionData in metadata.versions do
			if satisfies(versionData.package.version) then
				table.insert(candidates, versionData)
			end
		end
		logger.debug(`{#candidates} of {#metadata.versions} candidate(s) match "{request.constraints}"`)

		-- Locked versions first, then newest first.
		table.sort(candidates, function(a: PackageVersion, b: PackageVersion): boolean
			const aLocked = lockedIds[packageId.format(request.scope, request.name, a.package.version)] ~= nil
			const bLocked = lockedIds[packageId.format(request.scope, request.name, b.package.version)] ~= nil
			if aLocked ~= bLocked then
				return aLocked
			end

			return isNewerVersion(a.package.version, b.package.version)
		end)

		-- The first candidate the requester may depend on that does not clash with a version already in the graph.
		local chosen: PackageVersion? = nil
		for _, candidate in candidates do
			const candidateSemver = parseSemver(candidate.package.version)
			if candidateSemver == nil or not isDependencyValid(request.requestRealm, packageRealm(candidate)) then
				continue
			end

			local conflicts = false
			for _, entry in activated do
				if wallySemver.compatible(candidateSemver, entry.semver) then
					conflicts = true
					break
				end
			end

			if not conflicts then
				chosen = candidate
				break
			end
		end

		if chosen == nil then
			logger.warn(`no compatible version for {fullName}@{request.constraints}`)
			table.insert(failures, `{fullName}: no compatible version for "{request.constraints}"`)
			continue
		end

		const chosenVersion = chosen.package.version
		const chosenRealm = promoteRealm(packageRealm(chosen), request.originRealm)
		const chosenPackageId = packageId.format(request.scope, request.name, chosenVersion)
		logger.debug(`chose {fullName}@{chosenVersion} (realm={chosenRealm})`)

		activate({
			scope = request.scope,
			name = request.name,
			version = chosenVersion,
			realm = chosenRealm,
			packageId = chosenPackageId,
			dependencies = {},
		})
		addEdge(request, chosenPackageId)
		enqueueDependencies(chosen, chosenPackageId, chosenRealm)
	end

	return resolved, rootAliases, failures, unresolvedRoots
end

return resolveAsync
