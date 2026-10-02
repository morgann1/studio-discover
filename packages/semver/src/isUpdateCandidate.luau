--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const isNewerVersion = require(StudioDiscover.Libraries.Semver.isNewerVersion)
const parseSemver = require(StudioDiscover.Libraries.Semver.parseSemver)

--[[
	Whether a root installed at `from` may be offered `to` as an update. `to` has to
		be newer, and a prerelease `to` is only offered to a prerelease `from` on the
		same major.minor.patch. That is the prerelease rule a requirement on `from`
		follows, so neither `wally update` nor `pesde update` moves a stable root
		onto a prerelease.
]]
const function isUpdateCandidate(from: string, to: string): boolean
	if not isNewerVersion(to, from) then
		return false
	end

	const toSemver = parseSemver(to)
	if toSemver == nil or #toSemver.prerelease == 0 then
		return true
	end

	const fromSemver = parseSemver(from)
	return fromSemver ~= nil
		and #fromSemver.prerelease > 0
		and fromSemver.major == toSemver.major
		and fromSemver.minor == toSemver.minor
		and fromSemver.patch == toSemver.patch
end

return isUpdateCandidate
