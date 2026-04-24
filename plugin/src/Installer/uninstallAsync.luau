--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local applyRootsAsync = require(StudioDiscover.Source.Installer.applyRootsAsync)
local createLogger = require(StudioDiscover.Source.Util.createLogger)
local lockfile = require(StudioDiscover.Source.Installer.Wally.lockfile)
local resolveAsync = require(StudioDiscover.Source.Installer.Wally.resolveAsync)
local runWithBusyLock = require(StudioDiscover.Source.Installer.runWithBusyLock)
local snapshotRoots = require(StudioDiscover.Source.Installer.Wally.snapshotRoots)
local types = require(StudioDiscover.Source.Installer.types)
local uninstallPesdeAsync = require(StudioDiscover.Source.Installer.uninstallPesdeAsync)

local logger = createLogger.createLogger("wally.installer.uninstall")

type Realm = "shared" | "server"
type Registry = types.Registry
type RootRequest = types.RootRequest

export type UninstallResult = {
	ok: boolean,
	error: string?,
}

local function runUninstall(scope: string, name: string, realm: Realm): UninstallResult
	logger.info(`uninstall {scope}/{name} realm={realm}`)

	local priorRoots = snapshotRoots()
	local remaining: { RootRequest } = {}
	local didMatch = false
	for _, prior in priorRoots do
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
		}
	end

	local lockData = lockfile.load()
	logger.info(`resolve starting ({#remaining} remaining root(s))`)
	local resolved, rootAliases, resolutionFailures = resolveAsync(remaining, lockData, nil)
	for _, failure in resolutionFailures do
		logger.warn(`resolve failure: {failure}`)
	end

	local result = applyRootsAsync(resolved, rootAliases, `Uninstall {scope}/{name}`, nil)
	if not result.ok then
		return {
			ok = false,
			error = result.error or "Uninstall failed",
		}
	end

	logger.info(`uninstall succeeded: {scope}/{name}`)
	return {
		ok = true,
		error = nil,
	}
end

local function uninstallAsync(scope: string, name: string, realm: Realm, registry: Registry?): UninstallResult
	if registry == "pesde" then
		return uninstallPesdeAsync(scope, name, realm)
	end

	return runWithBusyLock(function(): UninstallResult
		logger.warn(`uninstall rejected: another installer operation is in progress`)
		return {
			ok = false,
			error = "Another installer operation is in progress.",
		}
	end, function(): UninstallResult
		return runUninstall(scope, name, realm)
	end, function(err): UninstallResult
		logger.error(`uninstall crashed for {scope}/{name}: {err}`)
		return {
			ok = false,
			error = `Uninstall failed: {err}`,
		}
	end)
end

return uninstallAsync
