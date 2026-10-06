--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const exhaustiveMatch = require(StudioDiscover.Libraries.Core.exhaustiveMatch)
const fetchMetadataAsync = require(StudioDiscover.Libraries.PesdeRegistry.Api.fetchMetadataAsync)
const isNewerVersion = require(StudioDiscover.Libraries.Semver.isNewerVersion)
const realmFromTarget = require(StudioDiscover.Libraries.PesdeRegistry.realmFromTarget)
const types = require(StudioDiscover.Libraries.Core.types)

type VersionEntry = fetchMetadataAsync.VersionEntry

-- Each version's roblox target if it has one, otherwise its roblox_server target.
const function pickTargets(entries: { VersionEntry }): { [string]: VersionEntry? }
	const picked: { [string]: VersionEntry? } = {}
	for _, entry in entries do
		const current = picked[entry.version]
		if current == nil or (current.target == "roblox_server" and entry.target == "roblox") then
			picked[entry.version] = entry
		end
	end

	return picked
end

const function toPackageVersion(entry: VersionEntry): types.PackageVersion
	const realm = realmFromTarget(entry.target)

	-- The package screen lists peer dependencies alongside the standard ones.
	const standard: types.DependencyMap = {}
	const peer: types.DependencyMap = {}
	const dev: types.DependencyMap = {}
	for _, dependency in entry.dependencies do
		const value = `{dependency.name}@{dependency.versionReq}`
		const ty = dependency.ty
		if ty == "dev" then
			dev[dependency.alias] = value
		elseif ty == "peer" then
			peer[dependency.alias] = value
		elseif ty == "standard" then
			standard[dependency.alias] = value
		else
			exhaustiveMatch(ty)
		end
	end

	for alias, value in peer do
		if standard[alias] == nil then
			standard[alias] = value
		end
	end

	return {
		package = {
			authors = entry.authors,
			description = entry.description,
			license = entry.license,
			realm = realm,
			version = entry.version,
		},
		dependencies = if realm == "shared" then standard else {},
		["server-dependencies"] = if realm == "server" then standard else {},
		["dev-dependencies"] = dev,
	}
end

--[[
	Fetches every version of a package published for a Roblox target, newest first,
		in the shape the package screen renders, or returns nil and why not. A package
		pesde doesn't have comes back with no versions.
]]
const function getMetadataAsync(scope: string, name: string): (types.PackageMetadata?, string?)
	const metadata, err, missing = fetchMetadataAsync(scope, name)
	if missing then
		return { versions = {} }, nil
	elseif metadata == nil then
		return nil, err
	end

	const picked = pickTargets(metadata.versions)

	const versionKeys: { string } = {}
	for version in picked do
		table.insert(versionKeys, version)
	end
	table.sort(versionKeys, isNewerVersion)

	const versions: { types.PackageVersion } = {}
	for _, version in versionKeys do
		const entry = picked[version]
		if entry ~= nil then
			table.insert(versions, toPackageVersion(entry))
		end
	end

	if #versions == 0 then
		return nil, "No Roblox-compatible versions found"
	end

	return { versions = versions }, nil
end

return getMetadataAsync
