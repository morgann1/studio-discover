--!strict

export type PrereleaseIdent = number | string

export type Semver = {
	read major: number,
	read minor: number,
	read patch: number,
	read prerelease: { PrereleaseIdent },
}

const function parsePrerelease(raw: string): { PrereleaseIdent }
	const idents: { PrereleaseIdent } = {}
	for part in raw:gmatch("[^%.]+") do
		const number = if part:match("^%d+$") ~= nil then tonumber(part) else nil
		table.insert(idents, if number ~= nil then number else part)
	end

	return idents
end

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
