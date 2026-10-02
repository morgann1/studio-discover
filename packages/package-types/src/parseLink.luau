--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const trim = require(StudioDiscover.Libraries.Core.trim)

--[[
	Where a Wally link module points: the expression holding `_Index`, the
		package's folder in it, and the module inside that.
]]
export type Link = {
	read indexPath: string,
	read packageId: string,
	read moduleName: string,
}

const REQUIRE_PATTERN = '^(.-)require%((.-)%["([^"]+)"%]%["([^"]+)"%]%)$'

--[[
	Reads a Wally link module's source, as the wally CLI or Discover writes it, and
		returns where it points. Returns nil for anything else.

	A link's first line of code is the require, either returned directly or held
		in `REQUIRED_MODULE` so its types can be forwarded. Matching that whole line
		keeps a package's own module from passing for a link because it indexes a
		string that happens to contain `@`.
]]
const function parseLink(source: string): Link?
	for _, line in string.split(source, "\n") do
		const code = trim(line)
		if code == "" or string.sub(code, 1, 2) == "--" then
			continue
		end

		const head, indexPath, packageId, moduleName = code:match(REQUIRE_PATTERN)
		if head ~= "return " and head ~= "local REQUIRED_MODULE = " then
			return nil
		end

		if indexPath == nil or packageId == nil or moduleName == nil then
			return nil
		end

		return { indexPath = indexPath, packageId = packageId, moduleName = moduleName }
	end

	return nil
end

return parseLink
