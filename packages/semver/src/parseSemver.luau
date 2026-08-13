--!strict

export type PrereleaseIdent = number | string

export type Semver = {
	major: number,
	minor: number,
	patch: number,
	prerelease: { PrereleaseIdent },
}

local function parsePrerelease(raw: string): { PrereleaseIdent }
	local idents: { PrereleaseIdent } = {}
	for part in raw:gmatch("[^%.]+") do
		if part:match("^%d+$") then
			table.insert(idents, tonumber(part) :: number)
		else
			table.insert(idents, part)
		end
	end
	return idents
end

local function parseSemver(version: string): Semver?
	local cleaned = (version:gsub("^v", ""))
	cleaned = (cleaned:gsub("%+[^%s]+$", ""))
	local major, minor, patch, rest = cleaned:match("^(%d+)%.(%d+)%.(%d+)(.*)$")
	if major == nil then
		return nil
	end
	local prerelease: { PrereleaseIdent } = {}
	if rest ~= nil and rest ~= "" then
		local pre = (rest :: string):match("^%-(.+)$")
		if pre ~= nil then
			prerelease = parsePrerelease(pre)
		end
	end
	return {
		major = tonumber(major) :: number,
		minor = tonumber(minor) :: number,
		patch = tonumber(patch) :: number,
		prerelease = prerelease,
	}
end

return parseSemver
