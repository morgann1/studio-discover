--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const applyRootsAsync = require(StudioDiscover.Source.Installer.applyRootsAsync)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const countKeys = require(StudioDiscover.Source.Util.countKeys)
const createInstallReporter = require(StudioDiscover.Source.Installer.createInstallReporter)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const runWithBusyLock = require(StudioDiscover.Source.Installer.runWithBusyLock)
const types = require(StudioDiscover.Source.Installer.types)
const unresolvedRootsError = require(StudioDiscover.Source.Installer.unresolvedRootsError)

const formatNevermorePackageId = require(StudioDiscover.Libraries.NevermoreRegistry.formatPackageId)
const loadNevermoreLockfile = require(StudioDiscover.Libraries.NevermoreRegistry.loadLockfile)
const nevermoreApplyAsync = require(StudioDiscover.Libraries.NevermoreRegistry.applyAsync)
const nevermoreResolveAsync = require(StudioDiscover.Libraries.NevermoreRegistry.resolveAsync)
const nevermoreSnapshotRoots = require(StudioDiscover.Libraries.NevermoreRegistry.snapshotRoots)
const npmName = require(StudioDiscover.Libraries.NevermoreRegistry.npmName)
const saveNevermoreLockfileAsync = require(StudioDiscover.Libraries.NevermoreRegistry.saveLockfileAsync)

const logger = createLogger.createLogger("nevermore.installer.install")

const function runInstallAsync(
	request: types.InstallRequest,
	report: createInstallReporter.InstallReporter
): types.OperationResult
	const scope, name, version = request.scope, request.name, request.version
	logger.info(`install nevermore {scope}/{name}@{version}`)
	report.progress("Resolving dependencies...")

	-- Installing a package that is already a root replaces it, whatever its version.
	const roots: { coreTypes.RootRequest } = {}
	for _, prior in nevermoreSnapshotRoots() do
		if prior.scope == scope and prior.name == name then
			logger.info(`replacing prior root {prior.scope}/{prior.name}@{prior.version}`)
			continue
		end

		table.insert(roots, prior)
	end

	-- The loader finds modules by name, so a root goes by its own name.
	const root: coreTypes.RootRequest = {
		scope = scope,
		name = name,
		version = version,
		requestRealm = "shared",
		alias = name,
	}
	table.insert(roots, root)

	const locked = loadNevermoreLockfile()
	logger.info(`resolve starting ({#roots} root(s), lockfile has {countKeys(locked)} entries)`)
	const resolved, rootIds, resolutionFailures, unresolvedRoots = nevermoreResolveAsync(roots, locked, report.progress)

	for _, failure in resolutionFailures do
		logger.warn(`resolve failure: {failure}`)
	end

	const unresolvedError = unresolvedRootsError(unresolvedRoots, resolutionFailures)
	if unresolvedError ~= nil then
		return report.fail(unresolvedError, resolutionFailures)
	end

	logger.info(`resolve complete: {countKeys(resolved)} package(s)`)

	const rootId = formatNevermorePackageId(npmName(scope, name), version)
	const applyResult = applyRootsAsync(`Install {scope}/{name}@{version}`, function()
		const failures = nevermoreApplyAsync(resolved, rootIds, report.progress)
		saveNevermoreLockfileAsync(resolved)

		return failures
	end, `{rootId}:`)

	return report.finish(resolutionFailures, applyResult)
end

-- The Nevermore part of `installAsync`, which routes here by registry.
const function installNevermoreAsync(request: types.InstallRequest): types.OperationResult
	const report = createInstallReporter(request)

	return runWithBusyLock("Install", function()
		return runInstallAsync(request, report)
	end, function(message)
		report.fail(message, { message })
	end)
end

return installNevermoreAsync
