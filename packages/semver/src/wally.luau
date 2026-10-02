--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const matchesVersionReq = require(StudioDiscover.Libraries.Semver.matchesVersionReq)
const parseSemver = require(StudioDiscover.Libraries.Semver.parseSemver)
const parseVersionReq = require(StudioDiscover.Libraries.Semver.parseVersionReq)

type Semver = parseSemver.Semver

--[[
	Whether two versions are semver-compatible, so a graph that already holds one
		cannot take the other as well. The breaking part is the first non-zero one of
		major, minor, and patch, the same part a caret range holds fixed.
]]
const function compatible(a: Semver, b: Semver): boolean
	if a.major ~= 0 or b.major ~= 0 then
		return a.major == b.major
	elseif a.minor ~= 0 or b.minor ~= 0 then
		return a.minor == b.minor
	end

	return a.patch == b.patch
end

--[[
	Builds a predicate over version strings from a Wally constraint, or returns nil
		when any part of it does not parse.

	Wally's index holds constraints as semver 0.11 prints them: alternatives joined
		by ` || `, each a comma-separated set of full-version comparators. A version
		satisfies the constraint when it passes every comparator of one alternative.

	Each alternative is evaluated by pesde's semver 1.x rules. That is safe because
		0.11 and 1.x only disagree on partial versions, which 0.11 never prints.
]]
const function buildSatisfies(constraints: string): ((version: string) -> boolean)?
	const alternatives: { { parseVersionReq.Comparator } } = {}
	for _, alternative in string.split(constraints, "||") do
		const comparators = parseVersionReq(alternative)
		if comparators == nil then
			return nil
		end

		table.insert(alternatives, comparators)
	end

	return function(version: string): boolean
		const parsed = parseSemver(version)
		if parsed == nil then
			return false
		end

		for _, comparators in alternatives do
			if matchesVersionReq(comparators, parsed) then
				return true
			end
		end

		return false
	end
end

const wallySemver = table.freeze({
	buildSatisfies = buildSatisfies,
	compatible = compatible,
})

return wallySemver
