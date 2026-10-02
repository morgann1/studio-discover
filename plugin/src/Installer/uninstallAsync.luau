--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const applyAsync = require(StudioDiscover.WallyRegistry.applyAsync)
const applyRootsAsync = require(StudioDiscover.Source.Installer.applyRootsAsync)
const coreTypes = require(StudioDiscover.Core.types)
const createLogger = require(StudioDiscover.Core.createLogger)
const lockfile = require(StudioDiscover.WallyRegistry.lockfile)
const resolveAsync = require(StudioDiscover.WallyRegistry.resolveAsync)
const runWithBusyLock = require(StudioDiscover.Source.Installer.runWithBusyLock)
const snapshotRoots = require(StudioDiscover.WallyRegistry.snapshotRoots)
const types = require(StudioDiscover.Source.Installer.types)
const unresolvedRootsError = require(StudioDiscover.Source.Installer.unresolvedRootsError)
const uninstallPesdeAsync = require(StudioDiscover.Source.Installer.uninstallPesdeAsync)

const logger = createLogger.createLogger("wally.installer.uninstall")

const function runUninstallAsync(root: coreTypes.InstalledRoot): types.OperationResult
	const scope, name, realm = root.scope, root.name, root.realm
	logger.info(`uninstall {scope}/{name} realm={realm}`)

	const remaining: { coreTypes.RootRequest } = {}
	local didMatch = false
	for _, prior in snapshotRoots() do
		if prior.requestRealm == realm and prior.scope == scope and prior.name == name then
			didMatch = true
			logger.info(`removing root {prior.scope}/{prior.name}@{prior.version} (alias={prior.alias})`)
			continue
		end

		table.insert(remaining, prior)
	end

	if not didMatch then
		logger.warn(`no matching root for {scope}/{name} in {realm}`)

		return {
			ok = false,
			error = `No installed root matched {scope}/{name}`,
			failures = {},
		}
	end

	const lockData = lockfile.load()
	logger.info(`resolve starting ({#remaining} remaining root(s))`)
	const resolved, rootAliases, resolutionFailures, unresolvedRoots = resolveAsync(remaining, lockData, nil)

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
		const failures = applyAsync(resolved, rootAliases, nil)
		lockfile.saveAsync(resolved)

		return failures
	end)
end

--[[
	Removes an installed root, and any dependency that only it needed, by resolving
		and applying the roots that remain.
]]
const function uninstallAsync(root: coreTypes.InstalledRoot): types.OperationResult
	if root.registry == "pesde" then
		return uninstallPesdeAsync(root)
	end

	return runWithBusyLock("Uninstall", function()
		return runUninstallAsync(root)
	end)
end

return uninstallAsync
