--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local wallySemver = require(StudioDiscover.Source.Installer.Wally.semver)

local function normalizeConstraint(raw: string): string
	local trimmed = raw:match("^%s*(.-)%s*$") or raw
	if trimmed == "" or trimmed == "*" then
		return ""
	end
	if string.sub(trimmed, 1, 1) == "^" then
		return string.sub(trimmed, 2)
	end
	if string.sub(trimmed, 1, 1) == "~" then
		return string.sub(trimmed, 2)
	end
	return trimmed
end

local function buildSatisfies(constraint: string): (string) -> boolean
	local normalized = normalizeConstraint(constraint)
	if normalized == "" then
		return function()
			return true
		end
	end
	return wallySemver.buildSatisfies(normalized)
end

return table.freeze({
	buildSatisfies = buildSatisfies,
	compatible = wallySemver.compatible,
	normalizeConstraint = normalizeConstraint,
})
