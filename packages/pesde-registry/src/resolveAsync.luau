--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const coreTypes = require(StudioDiscover.Libraries.Core.types)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const fetchMetadataAsync = require(StudioDiscover.Libraries.PesdeRegistry.Api.fetchMetadataAsync)
const formatPackageId = require(StudioDiscover.Libraries.PesdeRegistry.formatPackageId)
const isNewerVersion = require(StudioDiscover.Libraries.Semver.isNewerVersion)
const pesdeSemver = require(StudioDiscover.Libraries.Semver.pesde)
const realmFromTarget = require(StudioDiscover.Libraries.PesdeRegistry.realmFromTarget)
const splitFullName = require(StudioDiscover.Libraries.Core.splitFullName)
const targetFromRealm = require(StudioDiscover.Libraries.PesdeRegistry.targetFromRealm)
const types = require(StudioDiscover.Libraries.PesdeRegistry.types)

const logger = createLogger.createLogger("pesde.installer.resolve")

type Realm = coreTypes.Realm
type PesdeResolvedPackage = types.PesdeResolvedPackage
type VersionEntry = fetchMetadataAsync.VersionEntry

type DependencyRequest = {
	read parentId: string,
	read alias: string,
	read scope: string,
	read name: string,
	read versionReq: string,
	read target: types.Target,
}

const function findVersion(
	metadata: fetchMetadataAsync.PesdeMetadata,
	target: types.Target,
	version: string
): VersionEntry?
	for _, entry in metadata.versions do
		if entry.target == target and entry.version == version then
			return entry
		end
	end

	return nil
end

const function pickNewestMatch(
	metadata: fetchMetadataAsync.PesdeMetadata,
	target: types.Target,
	satisfies: (version: string) -> boolean
): VersionEntry?
	local newest: VersionEntry? = nil
	for _, entry in metadata.versions do
		if entry.target ~= target or not satisfies(entry.version) then
			continue
		end

		if newest == nil or isNewerVersion(entry.version, newest.version) then
			newest = entry
		end
	end

	return newest
end

--[[
	Reads the dependency requests out of one published version, along with the
		entries it cannot install.

	A root's peer dependencies install with it, since nothing above it provides
		them. Below the roots, peers are left to whoever depends on the package. Dev
		dependencies never install. Wally-proxied dependencies, and dependencies on the
		other target, are not supported yet: a link across realms would need a path
		out of its own packages folder.
]]
const function readDependencies(
	entry: VersionEntry,
	parentId: string,
	isRoot: boolean
): ({ DependencyRequest }, { string })
	const requests: { DependencyRequest } = {}
	const failures: { string } = {}

	for _, dependency in entry.dependencies do
		if dependency.ty == "dev" or (dependency.ty == "peer" and not isRoot) then
			continue
		end

		const scope, name = splitFullName(dependency.name)
		if scope == nil or name == nil then
			table.insert(failures, `{dependency.alias}: could not parse "{dependency.name}"`)
			continue
		elseif dependency.kind == "wally" then
			table.insert(failures, `{dependency.alias}: wally-proxied dep "{dependency.name}" not yet supported`)
			continue
		elseif dependency.target ~= nil and dependency.target ~= entry.target then
			table.insert(
				failures,
				`{dependency.alias}: dependency on another target "{dependency.target}" not yet supported`
			)
			continue
		end

		table.insert(requests, {
			parentId = parentId,
			alias = dependency.alias,
			scope = scope,
			name = name,
			versionReq = dependency.versionReq,
			target = entry.target,
		})
	end

	return requests, failures
end

--[[
	Walks the locked edges down from `rootId` and returns every package in its
		subtree, the root first. Returns nil when the root, or any package an edge
		points at, is missing from the lock.
]]
const function collectLockedSubtree(
	locked: { [string]: PesdeResolvedPackage },
	rootId: string
): { PesdeResolvedPackage }?
	const root = locked[rootId]
	if root == nil then
		return nil
	end

	const subtree = { root }
	const seen: { [string]: true? } = { [rootId] = true }
	local head = 1
	while head <= #subtree do
		const pkg = subtree[head]
		head += 1

		for _, dependency in pkg.dependencies do
			if seen[dependency.packageId] then
				continue
			end

			const lockedDependency = locked[dependency.packageId]
			if lockedDependency == nil then
				return nil
			end

			seen[dependency.packageId] = true
			table.insert(subtree, lockedDependency)
		end
	end

	return subtree
end

--[[
	Resolves `roots` and everything they depend on against pesde's registry, taking
		the newest version that satisfies each request.

	Like `pesde install`, a root whose package id is in `locked` keeps its locked
		subtree as is, without fetching metadata. A root whose locked subtree is
		incomplete resolves fresh. Pass an empty lock to resolve everything fresh, as
		`pesde update` does.

	Returns the graph keyed by package id, each root's alias keyed the same way, the
		failures along the way, and the roots it could not resolve at all. Applying
		without those roots would uninstall them, so callers stop instead.

	A request reuses a version already in the graph for the same realm when it
		satisfies it, including a locked one.
]]
const function resolveAsync(
	roots: { coreTypes.RootRequest },
	locked: { [string]: PesdeResolvedPackage },
	onProgress: coreTypes.ProgressCallback?
): (
	{ [string]: PesdeResolvedPackage },
	{ [string]: string },
	{ string },
	{ coreTypes.RootRequest }
)
	const resolved: { [string]: PesdeResolvedPackage } = {}
	const rootAliases: { [string]: string } = {}
	const failures: { string } = {}
	const unresolvedRoots: { coreTypes.RootRequest } = {}
	const activatedByName: { [string]: { PesdeResolvedPackage }? } = {}
	const queue: { DependencyRequest } = {}

	const function place(pkg: PesdeResolvedPackage)
		resolved[pkg.packageId] = pkg

		const fullName = `{pkg.scope}/{pkg.name}`
		const activated = activatedByName[fullName] or {}
		table.insert(activated, pkg)
		activatedByName[fullName] = activated
	end

	const function activate(entry: VersionEntry, scope: string, name: string, realm: Realm): PesdeResolvedPackage
		const pkg: PesdeResolvedPackage = {
			packageId = formatPackageId(scope, name, entry.version, entry.target),
			scope = scope,
			name = name,
			version = entry.version,
			realm = realm,
			libPath = entry.libPath,
			dependencies = {},
		}
		place(pkg)

		return pkg
	end

	const function enqueueDependencies(entry: VersionEntry, parentId: string, isRoot: boolean)
		const requests, readFailures = readDependencies(entry, parentId, isRoot)
		table.move(requests, 1, #requests, #queue + 1, queue)
		table.move(readFailures, 1, #readFailures, #failures + 1, failures)
	end

	-- Locked subtrees go in before anything resolves, so fresh requests can reuse them.
	const freshRoots: { coreTypes.RootRequest } = {}
	for _, root in roots do
		const rootId = formatPackageId(root.scope, root.name, root.version, targetFromRealm(root.requestRealm))
		const subtree = collectLockedSubtree(locked, rootId)
		if subtree == nil then
			table.insert(freshRoots, root)
			continue
		end

		for _, pkg in subtree do
			if resolved[pkg.packageId] == nil then
				place(pkg)
			end
		end

		rootAliases[rootId] = root.alias
		logger.debug(`kept {rootId} and {#subtree - 1} locked dependencies`)
	end

	for _, root in freshRoots do
		const target = targetFromRealm(root.requestRealm)
		if onProgress ~= nil then
			onProgress(`Resolving {root.scope}/{root.name}@{root.version}...`)
		end

		const metadata, err = fetchMetadataAsync(root.scope, root.name)
		if metadata == nil then
			table.insert(failures, `{root.scope}/{root.name}: {err}`)
			table.insert(unresolvedRoots, root)
			continue
		end

		const entry = findVersion(metadata, target, root.version)
		if entry == nil then
			table.insert(failures, `{root.scope}/{root.name}@{root.version}: version not found for target {target}`)
			table.insert(unresolvedRoots, root)
			continue
		end

		const pkg = activate(entry, root.scope, root.name, root.requestRealm)
		rootAliases[pkg.packageId] = root.alias
		enqueueDependencies(entry, pkg.packageId, true)
	end

	-- A version already in the graph for the request's realm, when one satisfies it.
	const function findReusable(request: DependencyRequest): PesdeResolvedPackage?
		const realm = realmFromTarget(request.target)
		const satisfies = pesdeSemver.buildSatisfies(request.versionReq)
		if satisfies == nil then
			return nil
		end

		for _, pkg in activatedByName[`{request.scope}/{request.name}`] or {} do
			if pkg.realm == realm and satisfies(pkg.version) then
				return pkg
			end
		end

		return nil
	end

	-- Adds the newest version that satisfies the request to the graph, or records why there is none.
	const function resolveRequestAsync(request: DependencyRequest): PesdeResolvedPackage?
		const fullName = `{request.scope}/{request.name}`
		const satisfies = pesdeSemver.buildSatisfies(request.versionReq)
		if satisfies == nil then
			table.insert(failures, `{fullName}: could not parse constraint "{request.versionReq}"`)
			return nil
		end

		if onProgress ~= nil then
			onProgress(`Resolving {fullName}...`)
		end

		const metadata, err = fetchMetadataAsync(request.scope, request.name)
		if metadata == nil then
			table.insert(failures, `{fullName}: {err}`)
			return nil
		end

		const entry = pickNewestMatch(metadata, request.target, satisfies)
		if entry == nil then
			table.insert(failures, `{fullName}: no version matches "{request.versionReq}" for target {request.target}`)
			return nil
		end

		const pkg = activate(entry, request.scope, request.name, realmFromTarget(entry.target))
		logger.debug(`resolved {pkg.packageId}`)
		enqueueDependencies(entry, pkg.packageId, false)
		return pkg
	end

	local head = 1
	while head <= #queue do
		const request = queue[head]
		head += 1

		const chosen = findReusable(request) or resolveRequestAsync(request)
		if chosen == nil then
			continue
		end

		const parent = resolved[request.parentId]
		if parent ~= nil then
			table.insert(parent.dependencies, { alias = request.alias, packageId = chosen.packageId })
		end
	end

	return resolved, rootAliases, failures, unresolvedRoots
end

return resolveAsync
