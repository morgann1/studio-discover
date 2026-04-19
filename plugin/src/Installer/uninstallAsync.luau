--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local applyRootsAsync = require(StudioDiscover.Source.Installer.applyRootsAsync)
local createLogger = require(StudioDiscover.Source.Util.createLogger)
local lockfile = require(StudioDiscover.Source.Installer.lockfile)
local resolveAsync = require(StudioDiscover.Source.Installer.resolveAsync)
local snapshotRoots = require(StudioDiscover.Source.Installer.snapshotRoots)
local types = require(StudioDiscover.Source.Installer.types)

local logger = createLogger.createLogger("installer.uninstall")

type Realm = "shared" | "server"
type RootRequest = types.RootRequest

export type UninstallResult = {
	ok: boolean,
	error: string?,
}

-- Removes a top-level root by re-running the resolve/apply pipeline on the
-- remaining roots. `applyAsync` (via the shared pipeline) drops any `_Index`
-- entries no longer reached by an active root, effectively uninstalling the
-- package and any deps it was the last holder of.
local function uninstallAsync(scope: string, name: string, realm: Realm): UninstallResult
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

return uninstallAsync
