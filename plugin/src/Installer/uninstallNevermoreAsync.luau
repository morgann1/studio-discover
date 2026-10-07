--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const applyRootsAsync = require(StudioDiscover.Source.Installer.applyRootsAsync)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const runWithBusyLock = require(StudioDiscover.Source.Installer.runWithBusyLock)
const types = require(StudioDiscover.Source.Installer.types)
const unresolvedRootsError = require(StudioDiscover.Source.Installer.unresolvedRootsError)

const loadNevermoreLockfile = require(StudioDiscover.Libraries.NevermoreRegistry.loadLockfile)
const nevermoreApplyAsync = require(StudioDiscover.Libraries.NevermoreRegistry.applyAsync)
const nevermoreResolveAsync = require(StudioDiscover.Libraries.NevermoreRegistry.resolveAsync)
const nevermoreSnapshotRoots = require(StudioDiscover.Libraries.NevermoreRegistry.snapshotRoots)
const saveNevermoreLockfileAsync = require(StudioDiscover.Libraries.NevermoreRegistry.saveLockfileAsync)

const logger = createLogger.createLogger("nevermore.installer.uninstall")

const function runUninstallAsync(root: coreTypes.InstalledRoot): types.OperationResult
	const scope, name = root.scope, root.name
	logger.info(`uninstall nevermore {scope}/{name}`)

	const remaining: { coreTypes.RootRequest } = {}
	local didMatch = false
	for _, prior in nevermoreSnapshotRoots() do
		if prior.scope == scope and prior.name == name then
			didMatch = true
			logger.info(`removing root {prior.scope}/{prior.name}@{prior.version}`)
			continue
		end

		table.insert(remaining, prior)
	end

	if not didMatch then
		logger.warn(`no matching Nevermore root for {scope}/{name}`)

		return {
			ok = false,
			error = `No installed Nevermore root matched {scope}/{name}`,
			failures = {},
		}
	end

	const locked = loadNevermoreLockfile()
	logger.info(`resolve starting ({#remaining} remaining root(s))`)
	const resolved, rootIds, resolutionFailures, unresolvedRoots = nevermoreResolveAsync(remaining, locked, nil)

	for _, failure in resolutionFailures do
		logger.warn(`resolve failure: {failure}`)
	end

	const unresolvedError = unresolvedRootsError(unresolvedRoots, resolutionFailures)
	if unresolvedError ~= nil then
		return {
			ok = false,
			error = unresolvedError,
			failures = resolutionFailures,
		}
	end

	return applyRootsAsync(`Uninstall {scope}/{name}`, function()
		const failures = nevermoreApplyAsync(resolved, rootIds, nil)
		saveNevermoreLockfileAsync(resolved)

		return failures
	end)
end

-- The Nevermore part of `uninstallAsync`, which routes here by registry.
const function uninstallNevermoreAsync(root: coreTypes.InstalledRoot): types.OperationResult
	return runWithBusyLock("Uninstall", function()
		return runUninstallAsync(root)
	end)
end

return uninstallNevermoreAsync
