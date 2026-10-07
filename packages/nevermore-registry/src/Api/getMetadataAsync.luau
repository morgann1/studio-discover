--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const fetchPackumentAsync = require(StudioDiscover.Libraries.NevermoreRegistry.Api.fetchPackumentAsync)
const fetchVersionAsync = require(StudioDiscover.Libraries.NevermoreRegistry.Api.fetchVersionAsync)
const isNewerVersion = require(StudioDiscover.Libraries.Semver.isNewerVersion)
const npmName = require(StudioDiscover.Libraries.NevermoreRegistry.npmName)
const parseSemver = require(StudioDiscover.Libraries.Semver.parseSemver)
const splitNpmName = require(StudioDiscover.Libraries.NevermoreRegistry.splitNpmName)
const types = require(StudioDiscover.Libraries.Core.types)

-- Whether a version is a prerelease, such as a Nevermore canary build.
const function isPrerelease(version: string): boolean
	const parsed = parseSemver(version)
	return parsed ~= nil and #parsed.prerelease > 0
end

-- Rewrites `{ ["@quenty/loader"] = "10.11.2" }` as the "quenty/loader@10.11.2" specs the package screen reads.
const function toDependencyMap(dependencies: { [string]: string }): types.DependencyMap
	const map: types.DependencyMap = {}
	for name, range in dependencies do
		const scope, shortName = splitNpmName(name)
		const spec = if scope ~= nil and shortName ~= nil then `{scope}/{shortName}` else name
		map[name] = `{spec}@{range}`
	end

	return map
end

--[[
	Fetches a package's versions, newest first, in the shape the package screen
		renders, or returns nil and why not. A package npm doesn't have comes back
		with no versions.

	Prereleases are left out, since Nevermore publishes a canary build for every
		change, unless the `latest` tag is itself a prerelease. npm's version list
		carries only dependencies, so every version shows the description, license,
		and authors of the latest one.

	Nevermore has no realms. The loader replicates each folder by its name, so every
		version reads as shared.
]]
const function getMetadataAsync(scope: string, name: string): (types.PackageMetadata?, string?)
	const fullName = npmName(scope, name)

	const packument, err, missing = fetchPackumentAsync(fullName)
	if missing then
		return { versions = {} }, nil
	elseif packument == nil then
		return nil, err
	end

	const latest = packument.latest
	const latestDocument, latestErr = fetchVersionAsync(fullName, latest or "latest")
	if latestDocument == nil then
		return nil, latestErr
	end

	const showsPrereleases = latest ~= nil and isPrerelease(latest)
	const entries = table.clone(packument.versions)
	table.sort(entries, function(a: fetchPackumentAsync.VersionEntry, b: fetchPackumentAsync.VersionEntry)
		return isNewerVersion(a.version, b.version)
	end)

	const versions: { types.PackageVersion } = {}
	for _, entry in entries do
		if isPrerelease(entry.version) and not showsPrereleases then
			continue
		end

		const packageVersion: types.PackageVersion = {
			package = {
				authors = latestDocument.authors,
				description = latestDocument.description,
				license = latestDocument.license,
				realm = "shared",
				version = entry.version,
			},
			dependencies = toDependencyMap(entry.dependencies),
			["server-dependencies"] = {},
			["dev-dependencies"] = {},
		}
		table.insert(versions, packageVersion)
	end

	return { versions = versions }, nil
end

return getMetadataAsync
