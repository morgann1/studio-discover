--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local containerName = require(StudioDiscover.Source.Installer.Pesde.containerName)

type Kind = "pesde" | "wally"

local function stripLeafExtension(leaf: string): string
	local stripped = leaf:gsub("%.luau?$", "")
	return stripped
end

local function libPathToChain(libPath: string?, packageName: string): { string }
	local chain: { string } = { packageName }
	if libPath == nil or libPath == "" then
		return chain
	end

	local parts = string.split(libPath, "/")
	local leaf = parts[#parts]
	if leaf == "init.luau" or leaf == "init.lua" then
		parts[#parts] = nil :: any
	else
		parts[#parts] = stripLeafExtension(leaf)
	end

	for _, part in parts do
		if part == "" or part == "." then
			continue
		end
		table.insert(chain, part)
	end

	return chain
end

local function formatFindChain(chain: { string }): string
	local parts: { string } = {}
	for _, name in chain do
		table.insert(parts, `:FindFirstChild("{name}")`)
	end
	return table.concat(parts, "")
end

local function buildSameRealmLink(
	alias: string,
	scope: string,
	name: string,
	version: string,
	libPath: string?,
	kind: Kind
): ModuleScript
	local outer = containerName.formatOuter(kind, scope, name, version)
	local prefix: string
	if kind == "wally" then
		prefix = `:FindFirstChild(".pesde"):FindFirstChild("{outer}")`
	else
		prefix = `:FindFirstChild(".pesde"):FindFirstChild("{outer}"):FindFirstChild("{version}")`
	end

	local chain = libPathToChain(libPath, name)
	local findChain = formatFindChain(chain)

	local link = Instance.new("ModuleScript")
	link.Name = alias
	link.Source = `return require(script.Parent{prefix}{findChain})`
	return link
end

return table.freeze({
	buildSameRealmLink = buildSameRealmLink,
	libPathToChain = libPathToChain,
	formatFindChain = formatFindChain,
})
