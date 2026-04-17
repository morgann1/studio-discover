--!strict

local Discover = script:FindFirstAncestor("Discover")

local parseSemver = require(Discover.Src.Util.parseSemver)

type Semver = parseSemver.Semver

local function compareSemver(a: Semver, b: Semver): number
	if a.major ~= b.major then
		return if a.major < b.major then -1 else 1
	end
	if a.minor ~= b.minor then
		return if a.minor < b.minor then -1 else 1
	end
	if a.patch ~= b.patch then
		return if a.patch < b.patch then -1 else 1
	end
	return 0
end

return compareSemver
