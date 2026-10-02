--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const applyAsync = require(StudioDiscover.Libraries.WallyRegistry.applyAsync)
const applyRootsAsync = require(StudioDiscover.Source.Installer.applyRootsAsync)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const countKeys = require(StudioDiscover.Source.Util.countKeys)
const createInstallReporter = require(StudioDiscover.Source.Installer.createInstallReporter)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const installPesdeAsync = require(StudioDiscover.Source.Installer.installPesdeAsync)
const lockfile = require(StudioDiscover.Libraries.WallyRegistry.lockfile)
const pickFreeAlias = require(StudioDiscover.Source.Installer.pickFreeAlias)
const resolveAlias = require(StudioDiscover.Source.Installer.resolveAlias)
const resolveAsync = require(StudioDiscover.Libraries.WallyRegistry.resolveAsync)
const runWithBusyLock = require(StudioDiscover.Source.Installer.runWithBusyLock)
const snapshotRoots = require(StudioDiscover.Libraries.WallyRegistry.snapshotRoots)
const types = require(StudioDiscover.Source.Installer.types)
const unresolvedRootsError = require(StudioDiscover.Source.Installer.unresolvedRootsError)

const logger = createLogger.createLogger("wally.installer.install")

const function runInstallAsync(
	request: types.InstallRequest,
	report: createInstallReporter.InstallReporter
): types.OperationResult
	const scope, name, version, realm = request.scope, request.name, request.version, request.realm
	logger.info(`install {scope}/{name}@{version} realm={realm}`)
	report.progress("Resolving dependencies...")

	-- Installing a package that is already a root replaces it, whatever its version.
	const roots: { coreTypes.RootRequest } = {}
	for _, prior in snapshotRoots() do
		if prior.requestRealm == realm and prior.scope == scope and prior.name == name then
			logger.info(`replacing prior root {prior.scope}/{prior.name}@{prior.version}`)
			continue
		end

		table.insert(roots, prior)
	end

	const baseAlias = resolveAlias(name)
	const alias = pickFreeAlias(baseAlias, function(candidate)
		for _, prior in roots do
			if prior.requestRealm == realm and prior.alias == candidate then
				return true
			end
		end

		return false
	end)

	if alias ~= baseAlias then
		logger.warn(`alias "{baseAlias}" collided with an installed root; using "{alias}" instead`)
	end

	table.insert(roots, {
		scope = scope,
		name = name,
		version = version,
		requestRealm = realm,
		alias = alias,
	})

	const lockData = lockfile.load()
	logger.info(`resolve starting ({#roots} root(s), lockfile has {countKeys(lockData)} entries)`)
	const resolved, rootAliases, resolutionFailures, unresolvedRoots = resolveAsync(roots, lockData, report.progress)

	for _, failure in resolutionFailures do
		logger.warn(`resolve failure: {failure}`)
	end

	const unresolvedError = unresolvedRootsError(unresolvedRoots, resolutionFailures)
	if unresolvedError ~= nil then
		return report.fail(unresolvedError, resolutionFailures)
	end

	logger.info(`resolve complete: {countKeys(resolved)} package(s) activated`)

	const applyResult = applyRootsAsync(`Install {scope}/{name}@{version}`, function()
		const failures = applyAsync(resolved, rootAliases, report.progress)
		lockfile.saveAsync(resolved)

		return failures
	end, `{scope}/{name}@{version}:`)

	return report.finish(resolutionFailures, applyResult)
end

--[[
	Installs one package version as a root, along with its dependencies, replacing
		the root's current version if it is already installed. Progress and the outcome
		also show on the package screen through `installerAtom`.
]]
const function installAsync(request: types.InstallRequest): types.OperationResult
	if request.registry == "pesde" then
		return installPesdeAsync(request)
	end

	const report = createInstallReporter(request)

	return runWithBusyLock("Install", function()
		return runInstallAsync(request, report)
	end, function(message)
		report.fail(message, { message })
	end)
end

return installAsync
