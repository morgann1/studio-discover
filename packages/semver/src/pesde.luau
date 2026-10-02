--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const matchesVersionReq = require(StudioDiscover.Libraries.Semver.matchesVersionReq)
const parseSemver = require(StudioDiscover.Libraries.Semver.parseSemver)
const parseVersionReq = require(StudioDiscover.Libraries.Semver.parseVersionReq)

--[[
	Builds a predicate over version strings from a pesde `version_req`, or returns nil
		when it does not parse. pesde sends requirements in semver 1.x's own syntax,
		so `^`, `~`, wildcards, and partial versions all keep their 1.x meaning.

	A bare `*` matches every version, prereleases included, as pesde's
		`version_matches` does.
]]
const function buildSatisfies(constraint: string): ((version: string) -> boolean)?
	const comparators = parseVersionReq(constraint)
	if comparators == nil then
		return nil
	elseif #comparators == 0 then
		return function()
			return true
		end
	end

	return function(version: string): boolean
		const parsed = parseSemver(version)
		return parsed ~= nil and matchesVersionReq(comparators, parsed)
	end
end

const pesdeSemver = table.freeze({
	buildSatisfies = buildSatisfies,
})

return pesdeSemver
