--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const matchesVersionReq = require(StudioDiscover.Libraries.Semver.matchesVersionReq)
const parseSemver = require(StudioDiscover.Libraries.Semver.parseSemver)
const parseVersionReq = require(StudioDiscover.Libraries.Semver.parseVersionReq)
const trim = require(StudioDiscover.Libraries.Core.trim)

--[[
	Rewrites one npm comparator set, such as `>=1.2.0 <2.0.0` or `1.2.0 - 1.4`, as the
		comma-separated semver 1.x requirement `parseVersionReq` reads.

	npm and semver 1.x agree on `^`, `~`, and the comparison operators, partial
		versions included. They disagree on a bare version, which is exact in npm and
		a caret range in semver 1.x, so a bare version gains an `=`. A lone wildcard
		allows everything, so it adds no comparator.
]]
const function toVersionReq(set: string): string
	const low, high = set:match("^(%S+)%s+%-%s+(%S+)$")
	if low ~= nil and high ~= nil then
		return `>={low},<={high}`
	end

	const comparators: { string } = {}
	const joined = set:gsub("([<>=~^]+)%s+", "%1")
	for token in joined:gmatch("%S+") do
		const operator, version = token:match("^([<>=~^]*)v?(.*)$")
		if version == "*" or version == "x" or version == "X" then
			continue
		end

		table.insert(comparators, `{if operator == "" then "=" else operator}{version}`)
	end

	return table.concat(comparators, ",")
end

--[[
	Builds a predicate over version strings from an npm range, such as `^1.2.0`,
		`3.10.0-quenty.2`, or `>=1.0.0 <2.0.0 || 3.x`, or returns nil when any part of
		it does not parse. A version satisfies the range when it passes every
		comparator of one `||` alternative.

	An empty range, `*`, and `x` match every release. As in npm, a prerelease only
		matches a comparator that names a prerelease on its own major.minor.patch.
]]
const function buildSatisfies(range: string): ((version: string) -> boolean)?
	const alternatives: { { parseVersionReq.Comparator } } = {}
	for _, alternative in string.split(range, "||") do
		const versionReq = toVersionReq(trim(alternative))
		const comparators: { parseVersionReq.Comparator }? = if versionReq == ""
			then {}
			else parseVersionReq(versionReq)
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

const npmSemver = table.freeze({
	buildSatisfies = buildSatisfies,
})

return npmSemver
