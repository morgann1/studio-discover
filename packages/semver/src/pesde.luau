--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const trim = require(StudioDiscover.Libraries.Core.trim)
const wallySemver = require(StudioDiscover.Libraries.Semver.wally)

--[[
	Reduces a pesde constraint to the Wally form `buildSatisfies` reads, or to "" for
		any version. A caret and a tilde both become a bare version, which Wally reads
		as a caret range.
]]
const function normalizeConstraint(raw: string): string
	const trimmed = trim(raw)
	if trimmed == "" or trimmed == "*" then
		return ""
	end

	const prefix = string.sub(trimmed, 1, 1)
	if prefix == "^" or prefix == "~" then
		return string.sub(trimmed, 2)
	end

	return trimmed
end

const function buildSatisfies(constraint: string): (version: string) -> boolean
	const normalized = normalizeConstraint(constraint)
	if normalized == "" then
		return function()
			return true
		end
	end

	return wallySemver.buildSatisfies(normalized)
end

const pesdeSemver = table.freeze({
	buildSatisfies = buildSatisfies,
	normalizeConstraint = normalizeConstraint,
})

return pesdeSemver
