--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const collectLockedSubtree = require(StudioDiscover.Libraries.Core.collectLockedSubtree)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const fetchPackumentAsync = require(StudioDiscover.Libraries.NevermoreRegistry.Api.fetchPackumentAsync)
const fetchVersionAsync = require(StudioDiscover.Libraries.NevermoreRegistry.Api.fetchVersionAsync)
const formatPackageId = require(StudioDiscover.Libraries.NevermoreRegistry.formatPackageId)
const isNewerVersion = require(StudioDiscover.Libraries.Semver.isNewerVersion)
const npmName = require(StudioDiscover.Libraries.NevermoreRegistry.npmName)
const npmSemver = require(StudioDiscover.Libraries.Semver.npm)
const parseSemver = require(StudioDiscover.Libraries.Semver.parseSemver)
const types = require(StudioDiscover.Libraries.NevermoreRegistry.types)

const logger = createLogger.createLogger("nevermore.installer.resolve")

type NevermoreResolvedPackage = types.NevermoreResolvedPackage

type DependencyRequest = {
	read parentId: string,
	read name: string,
	read range: string,
}

-- A version and its dependencies, from whichever document resolve read it out of.
type Release = {
	read version: string,
	read dependencies: { [string]: string },
}

const function dependenciesOf(pkg: NevermoreResolvedPackage): { coreTypes.Dependency }
	return pkg.dependencies
end

--[[
	Finds the version a range picks, or returns nil and why not. Nevermore pins most
		dependencies to one version, which npm serves on its own. Anything else reads
		every version and takes the newest that satisfies the range, as npm does.
]]
const function findReleaseAsync(name: string, range: string): (Release?, string?)
	if parseSemver(range) ~= nil then
		const document, err = fetchVersionAsync(name, range)
		return document, err
	end

	const satisfies = npmSemver.buildSatisfies(range)
	if satisfies == nil then
		return nil, `could not parse range "{range}"`
	end

	const packument, err = fetchPackumentAsync(name)
	if packument == nil then
		return nil, err
	end

	local newest: Release? = nil
	for _, entry in packument.versions do
		if satisfies(entry.version) and (newest == nil or isNewerVersion(entry.version, newest.version)) then
			newest = entry
		end
	end

	if newest == nil then
		return nil, `no version matches "{range}"`
	end

	return newest, nil
end

--[[
	Resolves `roots` and everything they depend on against npm, taking for each
		dependency the version its range picks.

	Like `npm install`, a root whose package id is in `locked` keeps its locked
		subtree as is, without fetching anything. A root whose locked subtree is
		incomplete resolves fresh. Pass an empty lock to resolve everything fresh, as
		`npm update` does. A range reuses the newest version already in the graph
		that satisfies it.

	Returns the graph keyed by package id, the roots' package ids, the failures
		along the way, and the roots it could not resolve at all. Applying without
		those roots would uninstall them, so callers stop instead.
]]
const function resolveAsync(
	roots: { coreTypes.RootRequest },
	locked: { [string]: NevermoreResolvedPackage },
	onProgress: coreTypes.ProgressCallback?
): ({ [string]: NevermoreResolvedPackage }, { string }, { string }, { coreTypes.RootRequest })
	const resolved: { [string]: NevermoreResolvedPackage } = {}
	const rootIds: { string } = {}
	const failures: { string } = {}
	const unresolvedRoots: { coreTypes.RootRequest } = {}
	const versionsByName: { [string]: { string }? } = {}
	const queue: { DependencyRequest } = {}

	const function place(pkg: NevermoreResolvedPackage)
		resolved[pkg.packageId] = pkg

		const versions = versionsByName[pkg.name] or {}
		table.insert(versions, pkg.version)
		versionsByName[pkg.name] = versions
	end

	const function activate(name: string, release: Release): NevermoreResolvedPackage
		const pkg: NevermoreResolvedPackage = {
			packageId = formatPackageId(name, release.version),
			name = name,
			version = release.version,
			dependencies = {},
		}
		place(pkg)

		-- Sorted, so a graph resolves the same way every time.
		const dependencyNames: { string } = {}
		for dependencyName in release.dependencies do
			table.insert(dependencyNames, dependencyName)
		end
		table.sort(dependencyNames)

		for _, dependencyName in dependencyNames do
			table.insert(queue, {
				parentId = pkg.packageId,
				name = dependencyName,
				range = release.dependencies[dependencyName],
			})
		end

		return pkg
	end

	-- Locked subtrees go in before anything resolves, so fresh requests can reuse them.
	const freshRoots: { coreTypes.RootRequest } = {}
	for _, root in roots do
		const rootId = formatPackageId(npmName(root.scope, root.name), root.version)
		const subtree = collectLockedSubtree(locked, rootId, dependenciesOf)
		if subtree == nil then
			table.insert(freshRoots, root)
			continue
		end

		for _, pkg in subtree do
			if resolved[pkg.packageId] == nil then
				place(pkg)
			end
		end

		table.insert(rootIds, rootId)
		logger.debug(`kept {rootId} and {#subtree - 1} locked dependencies`)
	end

	for _, root in freshRoots do
		const name = npmName(root.scope, root.name)
		if onProgress ~= nil then
			onProgress(`Resolving {name}@{root.version}...`)
		end

		const release, err = fetchVersionAsync(name, root.version)
		if release == nil then
			table.insert(failures, `{name}@{root.version}: {err}`)
			table.insert(unresolvedRoots, root)
			continue
		end

		table.insert(rootIds, activate(name, release).packageId)
	end

	-- The newest version already in the graph that satisfies a request, when one does.
	const function findReusable(request: DependencyRequest): string?
		const satisfies = npmSemver.buildSatisfies(request.range)
		if satisfies == nil then
			return nil
		end

		local newest: string? = nil
		for _, version in versionsByName[request.name] or {} do
			if satisfies(version) and (newest == nil or isNewerVersion(version, newest)) then
				newest = version
			end
		end

		return if newest ~= nil then formatPackageId(request.name, newest) else nil
	end

	const function resolveRequestAsync(request: DependencyRequest): string?
		if onProgress ~= nil then
			onProgress(`Resolving {request.name}...`)
		end

		const release, err = findReleaseAsync(request.name, request.range)
		if release == nil then
			table.insert(failures, `{request.name}@{request.range}: {err}`)
			return nil
		end

		const pkg = activate(request.name, release)
		logger.debug(`resolved {pkg.packageId}`)
		return pkg.packageId
	end

	local head = 1
	while head <= #queue do
		const request = queue[head]
		head += 1

		const chosenId = findReusable(request) or resolveRequestAsync(request)
		const parent = resolved[request.parentId]
		if chosenId ~= nil and parent ~= nil then
			table.insert(parent.dependencies, { alias = request.name, packageId = chosenId })
		end
	end

	return resolved, rootIds, failures, unresolvedRoots
end

return resolveAsync
