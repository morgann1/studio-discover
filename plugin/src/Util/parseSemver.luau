--!strict

export type Semver = {
	major: number,
	minor: number,
	patch: number,
}

local function parseSemver(version: string): Semver?
	local cleaned = (version:gsub("^v", ""))
	local major, minor, patch = cleaned:match("^(%d+)%.(%d+)%.(%d+)")
	if major == nil then
		return nil
	end
	return {
		major = tonumber(major) :: number,
		minor = tonumber(minor) :: number,
		patch = tonumber(patch) :: number,
	}
end

return parseSemver
