--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const parsePrerelease = require(StudioDiscover.Libraries.Semver.parsePrerelease)
const trim = require(StudioDiscover.Libraries.Core.trim)

--[[
	How a comparator compares. A wildcard like `1.*` reads as `=` on the parts it
		names, the way semver 1.x evaluates it.
]]
export type Operator = "=" | ">" | ">=" | "<" | "<=" | "~" | "^"

--[[
	One comparator of a version requirement. A partial version leaves `minor` or
		`patch` nil, and only a comparator with a patch can carry a prerelease.
]]
export type Comparator = {
	read operator: Operator,
	read major: number,
	read minor: number?,
	read patch: number?,
	read prerelease: { parsePrerelease.PrereleaseIdent },
}

const function isWildcard(part: string): boolean
	return part == "*" or part == "x" or part == "X"
end

-- A comparator without an operator is a caret range, or `=` when it holds a wildcard.
const function parseOperator(raw: string, hasWildcard: boolean): Operator?
	if raw == "" then
		return if hasWildcard then "=" else "^"
	elseif raw == "=" or raw == ">" or raw == ">=" or raw == "<" or raw == "<=" or raw == "~" or raw == "^" then
		return raw
	end

	return nil
end

-- Whether `raw` is a `.`-separated list of non-empty alphanumeric or `-` identifiers.
const function isIdentifierList(raw: string): boolean
	for _, identifier in string.split(raw, ".") do
		if identifier:match("^[%w%-]+$") == nil then
			return false
		end
	end

	return true
end

-- Parses one comparator, such as `>=1.2.3-rc.1`, `^1.2`, `~1`, or `1.*`, or returns nil.
const function parseComparator(raw: string): Comparator?
	const rawOperator, versionText = raw:match("^([<>=~^]*)%s*(.*)$")
	if rawOperator == nil or versionText == nil then
		return nil
	end

	const core, suffix = versionText:match("^([^%-+]*)(.*)$")
	if core == nil or suffix == nil then
		return nil
	end

	const parts = string.split(core, ".")
	if #parts > 3 or parts[1]:match("^%d+$") == nil then
		return nil
	end

	-- After a wildcard, only another wildcard may follow.
	const numbers: { number } = { tonumber(parts[1]) :: number }
	local hasWildcard = false
	for index = 2, #parts do
		const part = parts[index]
		if isWildcard(part) then
			hasWildcard = true
		elseif part:match("^%d+$") ~= nil and not hasWildcard then
			numbers[index] = tonumber(part) :: number
		else
			return nil
		end
	end

	-- A prerelease and build metadata may only follow a full version.
	const patch = numbers[3]
	const prerelease = suffix:match("^%-([^+]+)")
	const build = suffix:sub(if prerelease ~= nil then #prerelease + 2 else 1)
	if suffix ~= "" and patch == nil then
		return nil
	elseif prerelease ~= nil and not isIdentifierList(prerelease) then
		return nil
	elseif build ~= "" and (build:sub(1, 1) ~= "+" or not isIdentifierList(build:sub(2))) then
		return nil
	end

	const operator = parseOperator(rawOperator, hasWildcard)
	if operator == nil then
		return nil
	end

	return {
		operator = operator,
		major = numbers[1],
		minor = numbers[2],
		patch = patch,
		prerelease = if prerelease ~= nil then parsePrerelease(prerelease) else {},
	}
end

--[[
	Parses a semver 1.x version requirement: comma-separated comparators, or a lone
		`*`, `x`, or `X`, which parses to no comparators at all. Returns nil when any
		part of it does not parse, so a caller never mistakes a bad constraint for
		one that allows everything.
]]
const function parseVersionReq(raw: string): { Comparator }?
	const trimmed = trim(raw)
	if isWildcard(trimmed) then
		return {}
	end

	const comparators: { Comparator } = {}
	for _, part in string.split(trimmed, ",") do
		const comparator = parseComparator(trim(part))
		if comparator == nil then
			return nil
		end

		table.insert(comparators, comparator)
	end

	return comparators
end

return parseVersionReq
