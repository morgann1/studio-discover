--!strict

-- The package a root link points at.
export type RootLink = {
	read scope: string,
	read name: string,
	read version: string,
}

--[[
	Reads a root link's source, as `buildPackageLink.buildTopLevelLink` writes it,
		and returns the package its `./.pesde/scope+name/version/...` require points
		at. Returns nil for any other module.
]]
const function parseRootLink(source: string): RootLink?
	const path = source:match('^local module = require%("%./%.pesde/([^"]+)"%)\n')
	if path == nil then
		return nil
	end

	const scope, name, version = path:match("^([^/]+)%+([^/]+)/([^/]+)/")
	if scope == nil or name == nil or version == nil then
		return nil
	end

	return { scope = scope, name = name, version = version }
end

return parseRootLink
