--!strict

local HttpService = game:GetService("HttpService")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local zzlib = require(StudioDiscover.Packages.zzlib)

local downloadPackageAsync = require(StudioDiscover.Source.Api.Wally.downloadAsync)

local createLogger = require(StudioDiscover.Source.Util.createLogger)

local buildFileFilter = require(StudioDiscover.Source.Installer.fileFilter)
local buildTree = require(StudioDiscover.Source.Installer.buildTree)

local logger = createLogger.createLogger("installer.download")

type Entry = buildTree.Entry

-- Detects the leading directory a zip is nested under by looking for one of
-- the expected manifest files. Returns "" if the archive is flat at the root.
local function detectPrefix(zipData: string): string
	for _, filename in zzlib.files(zipData) do
		if
			string.match(filename, "wally%.toml$") ~= nil
			or string.match(filename, "default%.project%.json$") ~= nil
		then
			local dir = filename:match("^(.+/)[^/]+$")
			return dir or ""
		end
	end
	return ""
end

-- If a package ships a `default.project.json`, honor the `tree.$path` field
-- so we only materialize files under the declared source directory.
local function findSourcePath(zipData: string, prefix: string): string?
	local projectFileName = prefix .. "default.project.json"
	local projectJson: string? = nil
	pcall(function()
		projectJson = zzlib.unzip(zipData, projectFileName)
	end)
	if projectJson == nil then
		return nil
	end

	local success, decoded = pcall(function()
		return HttpService:JSONDecode(projectJson :: string)
	end)
	if not success or typeof(decoded) ~= "table" or decoded.tree == nil then
		return nil
	end

	local path = decoded.tree["$path"]
	if typeof(path) == "string" and path ~= "" and path ~= "." then
		return (string.gsub(path, "^%./", ""))
	end
	return nil
end

local function downloadAndExtractAsync(scope: string, name: string, version: string): (Instance?, string?)
	logger.debug(`fetch {scope}/{name}@{version}`)
	local zipData, err = downloadPackageAsync(scope, name, version)
	if zipData == nil then
		logger.warn(`download failed for {scope}/{name}@{version}: {err}`)
		return nil, `Failed to download: {err}`
	end

	local prefix = detectPrefix(zipData :: string)
	logger.debug(`zip prefix: "{prefix}"`)

	local wallyToml: string? = nil
	pcall(function()
		wallyToml = zzlib.unzip(zipData :: string, prefix .. "wally.toml")
	end)

	local shouldInclude = buildFileFilter(wallyToml)
	local sourcePath = findSourcePath(zipData :: string, prefix)
	logger.debug(`source path: {sourcePath or "(none)"}`)

	local entries: { Entry } = {}
	local extractOk, extractErr = pcall(function()
		for _, filename in zzlib.files(zipData :: string) do
			if filename:sub(-1) == "/" then
				continue
			end
			local relativePath = string.sub(filename, #prefix + 1)
			if not shouldInclude(relativePath) then
				continue
			end

			if sourcePath ~= nil then
				local sourcePathStr = sourcePath :: string
				local isUnderSource = string.sub(relativePath, 1, #sourcePathStr + 1) == sourcePathStr .. "/"
				local isSourceLuau = relativePath == sourcePathStr .. ".luau" or relativePath == sourcePathStr .. ".lua"
				local isSourceFile = relativePath == sourcePathStr
				if not isUnderSource and not isSourceFile and not isSourceLuau then
					continue
				end
			end

			local content = zzlib.unzip(zipData :: string, filename)
			local path = relativePath
			if sourcePath ~= nil then
				local sourcePathStr = sourcePath :: string
				if string.sub(path, 1, #sourcePathStr + 1) == sourcePathStr .. "/" then
					path = string.sub(path, #sourcePathStr + 2)
				elseif path == sourcePathStr .. ".luau" or path == sourcePathStr .. ".lua" then
					path = "init.luau"
				end
			end
			if path ~= "" then
				table.insert(entries, { path = name .. "/" .. path, content = content })
			end
		end
	end)
	if not extractOk then
		logger.warn(`extract failed for {scope}/{name}@{version}: {extractErr}`)
		return nil, `Failed to extract ZIP: {extractErr}`
	end

	logger.debug(`extracted {#entries} entries from {scope}/{name}@{version}`)
	return buildTree(entries, name)
end

return downloadAndExtractAsync
