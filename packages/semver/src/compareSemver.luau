--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const parseSemver = require(StudioDiscover.Libraries.Semver.parseSemver)

type Semver = parseSemver.Semver
type PrereleaseIdent = parseSemver.PrereleaseIdent

const function compareNumbers(a: number, b: number): number
	if a == b then
		return 0
	end

	return if a < b then -1 else 1
end

-- Numeric identifiers sort below alphanumeric ones, as semver specifies.
const function compareIdent(a: PrereleaseIdent, b: PrereleaseIdent): number
	if typeof(a) == "number" and typeof(b) == "number" then
		return compareNumbers(a, b)
	elseif typeof(a) == "number" then
		return -1
	elseif typeof(b) == "number" then
		return 1
	elseif a == b then
		return 0
	end

	return if a < b then -1 else 1
end

const function comparePrerelease(a: { PrereleaseIdent }, b: { PrereleaseIdent }): number
	-- A release has no prerelease, and sorts above any of its prereleases.
	if #a == 0 and #b == 0 then
		return 0
	elseif #a == 0 then
		return 1
	elseif #b == 0 then
		return -1
	end

	for index = 1, math.min(#a, #b) do
		const comparison = compareIdent(a[index], b[index])
		if comparison ~= 0 then
			return comparison
		end
	end

	return compareNumbers(#a, #b)
end

-- Returns -1, 0, or 1 as `a` sorts below, level with, or above `b` in semver precedence.
const function compareSemver(a: Semver, b: Semver): number
	if a.major ~= b.major then
		return compareNumbers(a.major, b.major)
	elseif a.minor ~= b.minor then
		return compareNumbers(a.minor, b.minor)
	elseif a.patch ~= b.patch then
		return compareNumbers(a.patch, b.patch)
	end

	return comparePrerelease(a.prerelease, b.prerelease)
end

return compareSemver
