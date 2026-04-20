--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local compareSemver = require(StudioDiscover.Source.Util.compareSemver)
local parseSemver = require(StudioDiscover.Source.Util.parseSemver)

type Semver = parseSemver.Semver

local function compatible(a: Semver, b: Semver): boolean
	if a.major == b.major and a.minor == b.minor and a.patch == b.patch then
		return true
	end
	if a.major == 0 and b.major == 0 then
		return a.minor == b.minor
	end
	return a.major == b.major
end

local function caretUpperBound(sv: Semver): Semver
	if sv.major ~= 0 then
		return { major = sv.major + 1, minor = 0, patch = 0 }
	end
	if sv.minor ~= 0 then
		return { major = 0, minor = sv.minor + 1, patch = 0 }
	end
	return { major = 0, minor = 0, patch = sv.patch + 1 }
end

type Check = {
	op: string,
	version: Semver,
}

local function buildSatisfies(constraints: string): (string) -> boolean
	local checks: { Check } = {}
	for raw in constraints:gmatch("[^,]+") do
		local constraint = raw:match("^%s*(.-)%s*$")
		if constraint == nil or constraint == "" then
			continue
		end
		local op, ver = constraint:match("^([><=]+)(.+)$")
		if op == nil then
			local sv = parseSemver(constraint)
			if sv ~= nil then
				table.insert(checks, { op = ">=", version = sv })
				table.insert(checks, { op = "<", version = caretUpperBound(sv) })
			end
		else
			local sv = parseSemver(ver :: string)
			if sv ~= nil then
				table.insert(checks, { op = op :: string, version = sv })
			end
		end
	end

	return function(version: string): boolean
		local sv = parseSemver(version)
		if sv == nil then
			return false
		end
		for _, check in checks do
			local cmp = compareSemver(sv, check.version)
			if check.op == ">=" and cmp < 0 then
				return false
			end
			if check.op == ">" and cmp <= 0 then
				return false
			end
			if check.op == "<=" and cmp > 0 then
				return false
			end
			if check.op == "<" and cmp >= 0 then
				return false
			end
			if check.op == "=" and cmp ~= 0 then
				return false
			end
		end
		return true
	end
end

return table.freeze({
	compatible = compatible,
	caretUpperBound = caretUpperBound,
	buildSatisfies = buildSatisfies,
})
