--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const compareSemver = require(StudioDiscover.Libraries.Semver.compareSemver)
const exhaustiveMatch = require(StudioDiscover.Libraries.Core.exhaustiveMatch)
const parseSemver = require(StudioDiscover.Libraries.Semver.parseSemver)
const parseVersionReq = require(StudioDiscover.Libraries.Semver.parseVersionReq)

type Comparator = parseVersionReq.Comparator
type Semver = parseSemver.Semver

--[[
	Compares `version` with only the parts `comparator` names, returning -1, 0, or 1.
		The parts it leaves out compare equal, and the prerelease only counts when
		the comparator names a patch.
]]
const function compareNamedParts(version: Semver, comparator: Comparator): number
	return compareSemver(version, {
		major = comparator.major,
		minor = comparator.minor or version.minor,
		patch = comparator.patch or version.patch,
		prerelease = if comparator.patch ~= nil then comparator.prerelease else version.prerelease,
	})
end

-- semver 1.x's `matches_caret`: the leftmost non-zero part the comparator names stays fixed.
const function matchesCaret(comparator: Comparator, version: Semver, comparison: number): boolean
	const minor = comparator.minor
	if version.major ~= comparator.major then
		return false
	elseif minor == nil then
		return true
	elseif comparator.patch == nil then
		return if comparator.major > 0 then version.minor >= minor else version.minor == minor
	elseif comparator.major > 0 then
		return comparison >= 0
	elseif minor > 0 then
		return version.minor == minor and comparison >= 0
	end

	return version.minor == minor and version.patch == comparator.patch and comparison >= 0
end

-- Whether `version` passes one comparator, following semver 1.x's `matches_impl`.
const function matchesComparator(comparator: Comparator, version: Semver): boolean
	const comparison = compareNamedParts(version, comparator)

	-- A partial comparator carries no prerelease, so only a release equals it.
	const isEqual = comparison == 0 and (comparator.patch ~= nil or #version.prerelease == 0)

	const operator = comparator.operator
	if operator == "=" then
		return isEqual
	elseif operator == ">" then
		return comparison > 0
	elseif operator == ">=" then
		return isEqual or comparison > 0
	elseif operator == "<" then
		return comparison < 0
	elseif operator == "<=" then
		return isEqual or comparison < 0
	elseif operator == "~" then
		return version.major == comparator.major
			and (comparator.minor == nil or version.minor == comparator.minor)
			and (isEqual or comparison > 0)
	elseif operator == "^" then
		return matchesCaret(comparator, version, comparison)
	end

	return exhaustiveMatch(operator)
end

--[[
	Whether `version` passes every comparator from `parseVersionReq`, the way
		semver 1.x evaluates a requirement. No comparators match every version.
]]
const function matchesVersionReq(comparators: { Comparator }, version: Semver): boolean
	for _, comparator in comparators do
		if not matchesComparator(comparator, version) then
			return false
		end
	end

	return true
end

return matchesVersionReq
