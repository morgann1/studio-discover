--!strict

const HttpService = game:GetService("HttpService")

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const zzlib = require(StudioDiscover.Libraries.Core.zzlib)

const asTable = require(StudioDiscover.Libraries.Core.asTable)
const buildFileFilter = require(StudioDiscover.Libraries.WallyRegistry.buildFileFilter)
const buildTree = require(StudioDiscover.Libraries.Core.buildTree)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const downloadAsync = require(StudioDiscover.Libraries.WallyRegistry.Api.downloadAsync)

const logger = createLogger.createLogger("wally.installer.download")

export type Extracted =
	{
		read ok: true,
		read tree: Instance,
		read pending: { buildTree.PendingSource },
	}
	| {
		read ok: false,
		read error: string,
	}

const function listZipFiles(zipData: string): { string }
	const names: { string } = {}
	for _, name in zzlib.files(zipData) do
		if name ~= nil then
			table.insert(names, name)
		end
	end

	return names
end

const function unzipFile(zipData: string, fileName: string): string?
	const ok, content = pcall(zzlib.unzip, zipData, fileName)
	return if ok then content else nil
end

-- Archives usually wrap the package in one directory. Its manifest marks where that directory ends.
const function detectPrefix(fileNames: { string }): string
	local prefix: string? = nil
	for _, fileName in fileNames do
		const directory, baseName = fileName:match("^(.-)([^/]+)$")
		if directory == nil or (baseName ~= "wally.toml" and baseName ~= "default.project.json") then
			continue
		end

		-- The shallowest manifest is the package's own; deeper ones belong to nested projects.
		if prefix == nil or #directory < #prefix then
			prefix = directory
		end
	end

	return prefix or ""
end

-- Returns the Rojo project's root `$path`, which is the part of the archive that installs.
const function findSourcePath(zipData: string, prefix: string): string?
	const projectJson = unzipFile(zipData, `{prefix}default.project.json`)
	if projectJson == nil then
		return nil
	end

	const ok, decoded = pcall(HttpService.JSONDecode, HttpService, projectJson)
	const project = if ok then asTable(decoded) else nil
	const tree = if project ~= nil then asTable(project.tree) else nil
	const path = if tree ~= nil then tree["$path"] else nil

	if typeof(path) == "string" and path ~= "" and path ~= "." then
		return (string.gsub(path, "^%./", ""))
	end

	return nil
end

-- Maps an archive path to its place in the package, or returns nil when it falls outside `sourcePath`.
const function relativeToSource(path: string, sourcePath: string?): string?
	if sourcePath == nil or path == sourcePath then
		return path
	elseif string.sub(path, 1, #sourcePath + 1) == `{sourcePath}/` then
		return string.sub(path, #sourcePath + 2)
	elseif path == `{sourcePath}.luau` or path == `{sourcePath}.lua` then
		return "init.luau"
	end

	return nil
end

--[[
	Downloads one package version and builds it into an unparented tree, keeping only
		the files the package's `wally.toml` and Rojo project say install.
]]
const function downloadAndExtractAsync(scope: string, name: string, version: string): Extracted
	logger.debug(`fetch {scope}/{name}@{version}`)

	const zipData, err = downloadAsync(scope, name, version)
	if zipData == nil then
		logger.warn(`download failed for {scope}/{name}@{version}: {err}`)
		return { ok = false, error = `Failed to download: {err}` }
	end

	const extractOk, extracted = pcall(function()
		const fileNames = listZipFiles(zipData)
		const prefix = detectPrefix(fileNames)
		const shouldInclude = buildFileFilter(unzipFile(zipData, `{prefix}wally.toml`))
		const sourcePath = findSourcePath(zipData, prefix)
		logger.debug(`zip prefix: "{prefix}", source path: {sourcePath or "(none)"}`)

		const entries: { buildTree.Entry } = {}
		for _, fileName in fileNames do
			if fileName:sub(-1) == "/" then
				continue
			end

			const relativePath = string.sub(fileName, #prefix + 1)
			if not shouldInclude(relativePath) then
				continue
			end

			const path = relativeToSource(relativePath, sourcePath)
			if path == nil or path == "" then
				continue
			end

			table.insert(entries, { path = `{name}/{path}`, content = zzlib.unzip(zipData, fileName) })
		end

		return entries
	end)

	if not extractOk then
		logger.warn(`extract failed for {scope}/{name}@{version}: {extracted}`)
		return { ok = false, error = `Failed to extract ZIP: {extracted}` }
	end

	logger.debug(`extracted {#extracted} entries from {scope}/{name}@{version}`)

	const tree, pending = buildTree(extracted, name)
	return { ok = true, tree = tree, pending = pending }
end

return downloadAndExtractAsync
