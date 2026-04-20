--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local zzlib = require(StudioDiscover.Packages.zzlib)

local downloadAsync = require(StudioDiscover.Source.Api.Pesde.downloadAsync)

local createLogger = require(StudioDiscover.Source.Util.createLogger)
local toml = require(StudioDiscover.Source.Util.toml)

local buildTree = require(StudioDiscover.Source.Installer.Wally.buildTree)
local tarAsync = require(StudioDiscover.Source.Installer.Pesde.tarAsync)

local logger = createLogger.createLogger("installer.pesdeDownload")

type Entry = buildTree.Entry
type Target = "roblox" | "roblox_server"

local IGNORED_FILES: { [string]: true } = {
	["foreman.toml"] = true,
	["aftman.toml"] = true,
	["rokit.toml"] = true,
	[".DS_Store"] = true,
	["default.project.json"] = true,
}

local function baseName(path: string): string
	return path:match("([^/]+)$") or path
end

local function isUnderDotGit(path: string): boolean
	return path == ".git" or path:sub(1, 5) == ".git/" or path:find("/%.git/") ~= nil or path:match("/%.git$") ~= nil
end

local function isGzip(data: string): boolean
	return #data >= 2 and string.byte(data, 1) == 0x1f and string.byte(data, 2) == 0x8b
end

local function extractLibPath(manifestSource: string): string?
	local ok, decoded = pcall(toml.deserialize, manifestSource)
	if not ok then
		return nil
	end
	local target = (decoded :: any).target
	if typeof(target) ~= "table" then
		return nil
	end
	local lib = target.lib
	if typeof(lib) == "string" then
		return lib
	end
	return nil
end

local function downloadAndExtractAsync(
	scope: string,
	name: string,
	version: string,
	target: Target
): (Instance?, string?, string?)
	logger.debug(`fetch {scope}/{name}@{version} {target}`)
	local archive, err = downloadAsync(scope, name, version, target)
	if archive == nil then
		return nil, nil, `Failed to download: {err}`
	end

	local tarData: string = archive :: string
	if isGzip(tarData) then
		local gunzipOk, result = pcall(zzlib.gunzip, tarData)
		if not gunzipOk then
			logger.warn(`gunzip failed for {scope}/{name}@{version}: {result}`)
			return nil, nil, `Failed to decompress: {result}`
		end
		tarData = result :: string
	end

	local parseOk, parseResult = pcall(tarAsync.parse, tarData)
	if not parseOk then
		logger.warn(`tar parse failed for {scope}/{name}@{version}: {parseResult}`)
		return nil, nil, `Failed to extract: {parseResult}`
	end

	local entries: { Entry } = {}
	local libPath: string? = nil
	for _, tarEntry in parseResult :: { tarAsync.TarEntry } do
		if tarEntry.kind ~= "file" then
			continue
		end
		if tarEntry.path == "pesde.toml" then
			libPath = extractLibPath(tarEntry.content)
		end
		if isUnderDotGit(tarEntry.path) then
			continue
		end
		if IGNORED_FILES[baseName(tarEntry.path)] then
			continue
		end
		table.insert(entries, {
			path = `{name}/{tarEntry.path}`,
			content = tarEntry.content,
		})
	end

	logger.debug(`extracted {#entries} entries from {scope}/{name}@{version}, libPath={libPath or "nil"}`)
	return buildTree(entries, name), libPath
end

return downloadAndExtractAsync
