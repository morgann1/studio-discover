--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local zzlib = require(StudioDiscover.Packages.zzlib)

local downloadAsync = require(StudioDiscover.Source.Api.Pesde.downloadAsync)

local createLogger = require(StudioDiscover.Source.Util.createLogger)

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

local function downloadAndExtractAsync(
	scope: string,
	name: string,
	version: string,
	target: Target
): (Instance?, string?)
	logger.debug(`fetch {scope}/{name}@{version} {target}`)
	local archive, err = downloadAsync(scope, name, version, target)
	if archive == nil then
		return nil, `Failed to download: {err}`
	end

	local gunzipOk, tarData = pcall(zzlib.gunzip, archive :: string)
	if not gunzipOk then
		logger.warn(`gunzip failed for {scope}/{name}@{version}: {tarData}`)
		return nil, `Failed to decompress: {tarData}`
	end

	local parseOk, parseResult = pcall(tarAsync.parse, tarData :: string)
	if not parseOk then
		logger.warn(`tar parse failed for {scope}/{name}@{version}: {parseResult}`)
		return nil, `Failed to extract: {parseResult}`
	end

	local entries: { Entry } = {}
	for _, tarEntry in parseResult :: { tarAsync.TarEntry } do
		if tarEntry.kind ~= "file" then
			continue
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

	logger.debug(`extracted {#entries} entries from {scope}/{name}@{version}`)
	return buildTree(entries, name)
end

return downloadAndExtractAsync
