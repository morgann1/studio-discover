--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const compareSemver = require(StudioDiscover.Semver.compareSemver)
const exhaustiveMatch = require(StudioDiscover.Core.exhaustiveMatch)
const parseSemver = require(StudioDiscover.Semver.parseSemver)
const trim = require(StudioDiscover.Core.trim)

type Semver = parseSemver.Semver

type Operator = ">=" | ">" | "<=" | "<" | "="

type Check = {
	read operator: Operator,
	read version: Semver,
}

--[[
	Whether two versions are semver-compatible, so a graph that already holds one
		cannot take the other as well. The breaking part is the first non-zero one of
		major, minor, and patch, the same part `caretUpperBound` bumps.
]]
const function compatible(a: Semver, b: Semver): boolean
	if a.major ~= 0 or b.major ~= 0 then
		return a.major == b.major
	elseif a.minor ~= 0 or b.minor ~= 0 then
		return a.minor == b.minor
	end

	return a.patch == b.patch
end

-- The first version a caret range on `version` excludes.
const function caretUpperBound(version: Semver): Semver
	if version.major ~= 0 then
		return { major = version.major + 1, minor = 0, patch = 0, prerelease = {} }
	elseif version.minor ~= 0 then
		return { major = 0, minor = version.minor + 1, patch = 0, prerelease = {} }
	end

	return { major = 0, minor = 0, patch = version.patch + 1, prerelease = {} }
end

const function parseOperator(raw: string): Operator?
	if raw == ">=" or raw == ">" or raw == "<=" or raw == "<" or raw == "=" then
		return raw
	end

	return nil
end

const function passes(check: Check, version: Semver): boolean
	const comparison = compareSemver(version, check.version)
	const operator = check.operator

	if operator == ">=" then
		return comparison >= 0
	elseif operator == ">" then
		return comparison > 0
	elseif operator == "<=" then
		return comparison <= 0
	elseif operator == "<" then
		return comparison < 0
	elseif operator == "=" then
		return comparison == 0
	end

	return exhaustiveMatch(operator)
end

--[[
	Builds a predicate over version strings from a Wally constraint: comma-separated
		comparators, where a bare version means a caret range on it.

	A comparator that does not parse adds no check.
]]
const function buildSatisfies(constraints: string): (version: string) -> boolean
	const checks: { Check } = {}

	for raw in constraints:gmatch("[^,]+") do
		const constraint = trim(raw)
		if constraint == "" then
			continue
		end

		const rawOperator, rawVersion = constraint:match("^([><=]+)(.+)$")
		if rawOperator == nil or rawVersion == nil then
			const version = parseSemver(constraint)
			if version ~= nil then
				const lower: Check = { operator = ">=", version = version }
				const upper: Check = { operator = "<", version = caretUpperBound(version) }
				table.insert(checks, lower)
				table.insert(checks, upper)
			end

			continue
		end

		const operator = parseOperator(rawOperator)
		const version = parseSemver(rawVersion)
		if operator ~= nil and version ~= nil then
			const check: Check = { operator = operator, version = version }
			table.insert(checks, check)
		end
	end

	return function(version: string): boolean
		const parsed = parseSemver(version)
		if parsed == nil then
			return false
		end

		for _, check in checks do
			if not passes(check, parsed) then
				return false
			end
		end

		return true
	end
end

const wallySemver = table.freeze({
	buildSatisfies = buildSatisfies,
	compatible = compatible,
})

return wallySemver
