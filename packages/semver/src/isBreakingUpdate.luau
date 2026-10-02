--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const parseSemver = require(StudioDiscover.Libraries.Semver.parseSemver)

--[[
	Whether moving from `from` to `to` crosses a breaking change: the leftmost nonzero
		component changes, so 1.2.0 to 2.0.0 and 0.9.0 to 0.10.0 are breaking but
		1.2.0 to 1.3.0 is not. A caret range on `from` would not accept `to`. Versions
		that do not parse are never breaking.
]]
const function isBreakingUpdate(from: string, to: string): boolean
	const fromSemver = parseSemver(from)
	const toSemver = parseSemver(to)
	if fromSemver == nil or toSemver == nil then
		return false
	end

	if fromSemver.major ~= 0 or toSemver.major ~= 0 then
		return fromSemver.major ~= toSemver.major
	elseif fromSemver.minor ~= 0 or toSemver.minor ~= 0 then
		return fromSemver.minor ~= toSemver.minor
	end

	return fromSemver.patch ~= toSemver.patch
end

return isBreakingUpdate
