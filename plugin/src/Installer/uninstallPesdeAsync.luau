--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const applyRootsAsync = require(StudioDiscover.Source.Installer.applyRootsAsync)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const runWithBusyLock = require(StudioDiscover.Source.Installer.runWithBusyLock)
const types = require(StudioDiscover.Source.Installer.types)
const unresolvedRootsError = require(StudioDiscover.Source.Installer.unresolvedRootsError)

const pesdeApplyAsync = require(StudioDiscover.Libraries.PesdeRegistry.applyAsync)
const pesdeResolveAsync = require(StudioDiscover.Libraries.PesdeRegistry.resolveAsync)
const pesdeSnapshotRoots = require(StudioDiscover.Libraries.PesdeRegistry.snapshotRoots)
const savePesdeLockfileAsync = require(StudioDiscover.Libraries.PesdeRegistry.saveLockfileAsync)

const logger = createLogger.createLogger("pesde.installer.uninstall")

const function runUninstallAsync(root: coreTypes.InstalledRoot): types.OperationResult
	const scope, name, realm = root.scope, root.name, root.realm
	logger.info(`uninstall pesde {scope}/{name} realm={realm}`)

	const remaining: { coreTypes.RootRequest } = {}
	local didMatch = false
	for _, prior in pesdeSnapshotRoots() do
		if prior.requestRealm == realm and prior.scope == scope and prior.name == name then
			didMatch = true
			logger.info(`removing root {prior.scope}/{prior.name}@{prior.version} (alias={prior.alias})`)
			continue
		end

		table.insert(remaining, prior)
	end

	if not didMatch then
		logger.warn(`no matching pesde root for {scope}/{name} in {realm}`)

		return {
			ok = false,
			error = `No installed pesde root matched {scope}/{name}`,
			failures = {},
		}
	end

	logger.info(`resolve starting ({#remaining} remaining root(s))`)
	const resolved, rootAliases, resolutionFailures, unresolvedRoots = pesdeResolveAsync(remaining, nil)

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
		const failures = pesdeApplyAsync(resolved, rootAliases, nil)
		savePesdeLockfileAsync(resolved)

		return failures
	end)
end

-- The pesde half of `uninstallAsync`, which routes here by registry.
const function uninstallPesdeAsync(root: coreTypes.InstalledRoot): types.OperationResult
	return runWithBusyLock("Uninstall", function()
		return runUninstallAsync(root)
	end)
end

return uninstallPesdeAsync
