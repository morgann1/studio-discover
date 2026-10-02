--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const compareSemver = require(StudioDiscover.Libraries.Semver.compareSemver)
const parseSemver = require(StudioDiscover.Libraries.Semver.parseSemver)

--[[
	A `table.sort` comparator that puts newer versions first. Versions that do not
		parse sort after every version that does, by their text, so the order stays
		consistent for any mix of the two.
]]
const function isNewerVersion(a: string, b: string): boolean
	const aSemver = parseSemver(a)
	const bSemver = parseSemver(b)

	if aSemver ~= nil and bSemver ~= nil then
		return compareSemver(aSemver, bSemver) > 0
	elseif aSemver ~= nil or bSemver ~= nil then
		return aSemver ~= nil
	end

	return a > b
end

return isNewerVersion
