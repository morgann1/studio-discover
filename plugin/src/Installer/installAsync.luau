--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local SettingsStore = require(StudioDiscover.Source.SettingsStore)

local applyRootsAsync = require(StudioDiscover.Source.Installer.applyRootsAsync)
local busyAtom = require(StudioDiscover.Source.Installer.busyAtom)
local createLogger = require(StudioDiscover.Source.Util.createLogger)
local formatName = require(StudioDiscover.Source.Util.formatName)
local installerAtom = require(StudioDiscover.Source.Installer.installerAtom)
local lockfile = require(StudioDiscover.Source.Installer.lockfile)
local packageId = require(StudioDiscover.Source.Installer.packageId)
local resolveAsync = require(StudioDiscover.Source.Installer.resolveAsync)
local snapshotRoots = require(StudioDiscover.Source.Installer.snapshotRoots)
local types = require(StudioDiscover.Source.Installer.types)

local logger = createLogger.createLogger("installer.install")

local function countPairs(t: { [any]: any }): number
	local count = 0
	for _ in t do
		count += 1
	end
	return count
end

type Realm = "shared" | "server"
type RootRequest = types.RootRequest
type InstallerState = types.InstallerState
type InstallerTarget = types.InstallerTarget

export type InstallResult = {
	ok: boolean,
	error: string?,
	failures: { string },
}

-- Adds a package as a new root, merging it with any prior roots snapshotted
-- from the packages folders. The resolve/apply pipeline handles dedup for
-- repeated installs of the same `(realm, scope, name)` and keeps unchanged
-- roots' already-downloaded `_Index` entries in place.
local function installAsync(scope: string, name: string, version: string, alias: string, realm: Realm?): InstallResult
	if busyAtom() then
		logger.warn(`install rejected: another installer operation is in progress`)
		return {
			ok = false,
			error = "Another installer operation is in progress.",
			failures = {},
		}
	end
	busyAtom(true)

	logger.info(`install {scope}/{name}@{version} alias={alias} realm={realm or "shared"}`)

	local target: InstallerTarget = {
		scope = scope,
		name = name,
		version = version,
	}

	local function setState(next: InstallerState)
		installerAtom(next)
	end

	local function progress(message: string)
		local current = installerAtom()
		logger.debug(`progress: {message}`)
		setState({
			status = current.status,
			message = message,
			errors = current.errors,
			target = target,
		})
	end

	if realm == "dev" :: any then
		logger.warn(`rejecting dev realm package {scope}/{name}@{version}`)
		local result: InstallResult = {
			ok = false,
			error = "Dev realm packages are not supported.",
			failures = {},
		}
		setState({
			status = "error",
			message = result.error,
			errors = {},
			target = target,
		})
		busyAtom(false)
		return result
	end

	setState({
		status = "running",
		message = "Resolving dependencies...",
		errors = {},
		target = target,
	})

	-- Per-package override wins over the naming-convention formatter; the
	-- Display Names settings page lets users pin a specific alias for a given
	-- package name (scope-agnostic) regardless of the global convention.
	local settings = SettingsStore.get().getStorage()
	local override: string? = nil
	for _, rule in settings.displayNames do
		if rule.name == name and rule.displayName ~= "" then
			override = rule.displayName
			break
		end
	end
	local formattedAlias: string
	if override ~= nil then
		formattedAlias = override
		logger.info(`alias "{alias}" overridden to "{formattedAlias}" (display-name rule)`)
	else
		formattedAlias = formatName(alias, settings.namingConvention)
		if formattedAlias ~= alias then
			logger.info(`alias "{alias}" formatted to "{formattedAlias}" ({settings.namingConvention})`)
		end
	end

	local newRoot: RootRequest = {
		scope = scope,
		name = name,
		version = version,
		requestRealm = realm or "shared",
		alias = formattedAlias,
	}

	-- Snapshot prior top-level roots so this install merges with them rather
	-- than wiping everything. Replace when the same package (realm+scope+name)
	-- is being re-installed — covers alias renames from convention changes.
	local priorRoots = snapshotRoots()
	local roots: { RootRequest } = {}
	for _, prior in priorRoots do
		local samePackage = prior.requestRealm == newRoot.requestRealm
			and prior.scope == newRoot.scope
			and prior.name == newRoot.name
		if not samePackage then
			table.insert(roots, prior)
		else
			logger.info(`replacing prior root {prior.scope}/{prior.name}@{prior.version} (same package)`)
		end
	end
	table.insert(roots, newRoot)

	local lockData = lockfile.load()
	logger.info(`resolve starting ({#roots} root(s), lockfile has {countPairs(lockData)} entries)`)
	local resolved, rootAliases, resolutionFailures = resolveAsync(roots, lockData, progress)

	if #resolutionFailures > 0 then
		for _, failure in resolutionFailures do
			logger.warn(`resolve failure: {failure}`)
		end
	end

	local rootPackageId = packageId.format(scope, name, version)
	if resolved[rootPackageId] == nil then
		local message = `Failed to resolve {scope}/{name}@{version}`
		if #resolutionFailures > 0 then
			message = `{message} ({table.concat(resolutionFailures, "; ")})`
		end
		logger.warn(`install aborted: {message}`)
		local result: InstallResult = {
			ok = false,
			error = message,
			failures = resolutionFailures,
		}
		setState({
			status = "error",
			message = message,
			errors = resolutionFailures,
			target = target,
		})
		busyAtom(false)
		return result
	end

	logger.info(`resolve complete: {countPairs(resolved)} package(s) activated`)

	-- Veto the commit when the package we set out to install is itself in
	-- `applyFailures`, so a botched download doesn't leave a "successful"
	-- install on the undo stack.
	local rootFailureMarker = `{scope}/{name}@{version}:`
	local decideCommit = function(applyFailures: { string }): boolean
		for _, failure in applyFailures do
			if string.sub(failure, 1, #rootFailureMarker) == rootFailureMarker then
				return false
			end
		end
		return true
	end

	logger.info("apply starting")
	local applyResult =
		applyRootsAsync(resolved, rootAliases, `Install {scope}/{name}@{version}`, progress, decideCommit)

	local allFailures: { string } = {}
	for _, failure in resolutionFailures do
		table.insert(allFailures, failure)
	end
	for _, failure in applyResult.failures do
		table.insert(allFailures, failure)
	end

	if not applyResult.ok then
		local message = applyResult.error or `Failed to install {scope}/{name}@{version}`
		if applyResult.error == "Root package did not apply" then
			message = `Failed to install {scope}/{name}@{version}`
			logger.warn(`install failed: root package did not apply`)
		else
			message = `Install failed: {message}`
		end
		setState({
			status = "error",
			message = message,
			errors = allFailures,
			target = target,
		})
		busyAtom(false)
		return {
			ok = false,
			error = message,
			failures = allFailures,
		}
	end

	logger.info(`apply complete ({#applyResult.failures} non-fatal warning(s))`)
	logger.info(`install succeeded: {scope}/{name}@{version}`)

	setState({
		status = "success",
		message = if #allFailures > 0
			then `Installed with {#allFailures} warning(s)`
			else `Installed {scope}/{name}@{version}`,
		errors = allFailures,
		target = target,
	})

	busyAtom(false)
	return {
		ok = true,
		error = nil,
		failures = allFailures,
	}
end

return installAsync
