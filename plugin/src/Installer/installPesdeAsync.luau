--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const applyRootsAsync = require(StudioDiscover.Source.Installer.applyRootsAsync)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const countKeys = require(StudioDiscover.Source.Util.countKeys)
const createInstallReporter = require(StudioDiscover.Source.Installer.createInstallReporter)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const pickFreeAlias = require(StudioDiscover.Source.Installer.pickFreeAlias)
const resolveAlias = require(StudioDiscover.Source.Installer.resolveAlias)
const runWithBusyLock = require(StudioDiscover.Source.Installer.runWithBusyLock)
const types = require(StudioDiscover.Source.Installer.types)
const unresolvedRootsError = require(StudioDiscover.Source.Installer.unresolvedRootsError)

const pesdeApplyAsync = require(StudioDiscover.Libraries.PesdeRegistry.applyAsync)
const pesdeResolveAsync = require(StudioDiscover.Libraries.PesdeRegistry.resolveAsync)
const pesdeSnapshotRoots = require(StudioDiscover.Libraries.PesdeRegistry.snapshotRoots)
const savePesdeLockfileAsync = require(StudioDiscover.Libraries.PesdeRegistry.saveLockfileAsync)

const logger = createLogger.createLogger("pesde.installer.install")

const function runInstallAsync(
	request: types.InstallRequest,
	report: createInstallReporter.InstallReporter
): types.OperationResult
	const scope, name, version, realm = request.scope, request.name, request.version, request.realm
	logger.info(`install pesde {scope}/{name}@{version} realm={realm}`)
	report.progress("Resolving dependencies...")

	-- Installing a package that is already a root replaces it, whatever its version.
	const roots: { coreTypes.RootRequest } = {}
	for _, prior in pesdeSnapshotRoots() do
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

	logger.info(`resolve starting ({#roots} root(s))`)
	const resolved, rootAliases, resolutionFailures, unresolvedRoots = pesdeResolveAsync(roots, report.progress)

	for _, failure in resolutionFailures do
		logger.warn(`resolve failure: {failure}`)
	end

	const unresolvedError = unresolvedRootsError(unresolvedRoots, resolutionFailures)
	if unresolvedError ~= nil then
		return report.fail(unresolvedError, resolutionFailures)
	end

	local rootId: string? = nil
	for id, pkg in resolved do
		if pkg.scope == scope and pkg.name == name and pkg.version == version then
			rootId = id
			break
		end
	end

	if rootId == nil then
		local message = `Failed to resolve {scope}/{name}@{version}`
		if #resolutionFailures > 0 then
			message ..= ` ({table.concat(resolutionFailures, "; ")})`
		end

		return report.fail(message, resolutionFailures)
	end

	logger.info(`resolve complete: {countKeys(resolved)} package(s)`)

	const applyResult = applyRootsAsync(`Install {scope}/{name}@{version}`, function()
		const failures = pesdeApplyAsync(resolved, rootAliases, report.progress)
		savePesdeLockfileAsync(resolved)

		return failures
	end, `{rootId}:`)

	return report.finish(resolutionFailures, applyResult)
end

-- The pesde half of `installAsync`, which routes here by registry.
const function installPesdeAsync(request: types.InstallRequest): types.OperationResult
	const report = createInstallReporter(request)

	return runWithBusyLock("Install", function()
		return runInstallAsync(request, report)
	end, function(message)
		report.fail(message, { message })
	end)
end

return installPesdeAsync
