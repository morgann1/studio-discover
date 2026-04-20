--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local parseSemver = require(StudioDiscover.Source.Util.parseSemver)

type Semver = parseSemver.Semver
type PrereleaseIdent = parseSemver.PrereleaseIdent

local function compareIdent(a: PrereleaseIdent, b: PrereleaseIdent): number
	local aIsNum = typeof(a) == "number"
	local bIsNum = typeof(b) == "number"
	if aIsNum and bIsNum then
		if (a :: number) == (b :: number) then
			return 0
		end
		return if (a :: number) < (b :: number) then -1 else 1
	end
	if aIsNum then
		return -1
	end
	if bIsNum then
		return 1
	end
	if (a :: string) == (b :: string) then
		return 0
	end
	return if (a :: string) < (b :: string) then -1 else 1
end

local function comparePrerelease(a: { PrereleaseIdent }, b: { PrereleaseIdent }): number
	if #a == 0 and #b == 0 then
		return 0
	end
	if #a == 0 then
		return 1
	end
	if #b == 0 then
		return -1
	end
	local len = math.min(#a, #b)
	for i = 1, len do
		local cmp = compareIdent(a[i], b[i])
		if cmp ~= 0 then
			return cmp
		end
	end
	if #a == #b then
		return 0
	end
	return if #a < #b then -1 else 1
end

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
	return comparePrerelease(a.prerelease, b.prerelease)
end

return compareSemver
