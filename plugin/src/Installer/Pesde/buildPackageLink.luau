--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local containerName = require(StudioDiscover.Source.Installer.Pesde.containerName)

type Kind = "pesde" | "wally"

local function stripLeafExtension(leaf: string): string
	local stripped = leaf:gsub("%.luau?$", "")
	return stripped
end

local function libPathSegments(libPath: string?): { string }
	if libPath == nil or libPath == "" then
		return {}
	end
	local parts = string.split(libPath, "/")
	local leaf = parts[#parts]
	if leaf == "init.luau" or leaf == "init.lua" then
		parts[#parts] = nil :: any
	else
		parts[#parts] = stripLeafExtension(leaf)
	end
	local result: { string } = {}
	for _, part in parts do
		if part == "" or part == "." then
			continue
		end
		table.insert(result, part)
	end
	return result
end

local function depPathSegments(scope: string, name: string, version: string, libPath: string?, kind: Kind): { string }
	local segments: { string } = {}
	if kind == "wally" then
		table.insert(segments, containerName.formatWallyName(scope, name, version))
	else
		table.insert(segments, containerName.formatPesdeName(scope, name))
		table.insert(segments, version)
	end
	table.insert(segments, name)
	for _, seg in libPathSegments(libPath) do
		table.insert(segments, seg)
	end
	return segments
end

local function transitiveUpLevels(dependantKind: Kind): number
	if dependantKind == "wally" then
		return 3
	end
	return 4
end

local function formatSource(path: string, typeExports: { string }?): string
	local body = `local module = require("{path}")\n`
	if typeExports ~= nil then
		for _, line in typeExports do
			body ..= line .. "\n"
		end
	end
	body ..= "return module"
	return body
end

local function buildTopLevelLink(
	alias: string,
	scope: string,
	name: string,
	version: string,
	libPath: string?,
	kind: Kind,
	typeExports: { string }?
): ModuleScript
	local segments = depPathSegments(scope, name, version, libPath, kind)
	local path = `./.pesde/{table.concat(segments, "/")}`
	local link = Instance.new("ModuleScript")
	link.Name = alias
	link.Source = formatSource(path, typeExports)
	return link
end

local function buildTransitiveLink(
	dependantKind: Kind,
	alias: string,
	scope: string,
	name: string,
	version: string,
	libPath: string?,
	kind: Kind,
	typeExports: { string }?
): ModuleScript
	local up = transitiveUpLevels(dependantKind)
	local prefix = "./" .. string.rep("../", up)
	local segments = depPathSegments(scope, name, version, libPath, kind)
	local path = `{prefix}{table.concat(segments, "/")}`
	local link = Instance.new("ModuleScript")
	link.Name = alias
	link.Source = formatSource(path, typeExports)
	return link
end

return table.freeze({
	buildTopLevelLink = buildTopLevelLink,
	buildTransitiveLink = buildTransitiveLink,
	libPathSegments = libPathSegments,
	depPathSegments = depPathSegments,
})
