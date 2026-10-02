--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const parsePrerelease = require(StudioDiscover.Libraries.Semver.parsePrerelease)

export type PrereleaseIdent = parsePrerelease.PrereleaseIdent

export type Semver = {
	read major: number,
	read minor: number,
	read patch: number,
	read prerelease: { PrereleaseIdent },
}

-- Parses `major.minor.patch` with an optional leading `v`, prerelease, and build metadata, or returns nil.
const function parseSemver(version: string): Semver?
	const withoutPrefix = version:gsub("^v", "")
	const cleaned = withoutPrefix:gsub("%+[^%s]+$", "")

	const major, minor, patch, rest = cleaned:match("^(%d+)%.(%d+)%.(%d+)(.*)$")
	if major == nil or minor == nil or patch == nil then
		return nil
	end

	const prerelease = if rest ~= nil then rest:match("^%-(.+)$") else nil

	return {
		major = tonumber(major) :: number,
		minor = tonumber(minor) :: number,
		patch = tonumber(patch) :: number,
		prerelease = if prerelease ~= nil then parsePrerelease(prerelease) else {},
	}
end

return parseSemver
