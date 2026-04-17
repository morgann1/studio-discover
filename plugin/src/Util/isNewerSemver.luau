--!strict

local Discover = script:FindFirstAncestor("Discover")

local compareSemver = require(Discover.Src.Util.compareSemver)
local parseSemver = require(Discover.Src.Util.parseSemver)

local function isNewerSemver(remote: string, current: string): boolean
	local r = parseSemver(remote)
	local c = parseSemver(current)
	if r == nil or c == nil then
		return false
	end
	return compareSemver(r, c) > 0
end

return isNewerSemver
