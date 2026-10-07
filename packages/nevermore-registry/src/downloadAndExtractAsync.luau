--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const zzlib = require(StudioDiscover.Libraries.Core.zzlib)

const buildTree = require(StudioDiscover.Libraries.Core.buildTree)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const httpClient = require(StudioDiscover.Libraries.NevermoreRegistry.Api.httpClient)
const nodeModulesPath = require(StudioDiscover.Libraries.NevermoreRegistry.nodeModulesPath)
const parseTar = require(StudioDiscover.Libraries.Core.parseTar)
const readProjectSourcePath = require(StudioDiscover.Libraries.Core.readProjectSourcePath)
const relativeToSource = require(StudioDiscover.Libraries.Core.relativeToSource)

const logger = createLogger.createLogger("nevermore.installer.download")

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

-- npm keeps every tarball at a path made from the package's name and version.
const function tarballPath(name: string, version: string): string
	const _, folderName = nodeModulesPath(name)
	return `/{name}/-/{folderName}-{version}.tgz`
end

--[[
	Downloads one package version and builds it into an unparented tree named for the
		package without its scope, as npm names its folder. Only the part of the
		tarball the package's Rojo project points at installs, as Rojo syncs it.
]]
const function downloadAndExtractAsync(name: string, version: string): Extracted
	const label = `{name}@{version}`
	logger.debug(`fetch {label}`)

	const archive, err = httpClient.getAsync(tarballPath(name, version), { ["Accept"] = "application/octet-stream" })
	if archive == nil then
		return { ok = false, error = `Failed to download: {err}` }
	end

	const gunzipOk, tarData = pcall(zzlib.gunzip, archive)
	if not gunzipOk then
		logger.warn(`gunzip failed for {label}: {tarData}`)
		return { ok = false, error = `Failed to decompress: {tarData}` }
	end

	const parseOk, tarEntries = pcall(parseTar, tarData)
	if not parseOk then
		logger.warn(`tar parse failed for {label}: {tarEntries}`)
		return { ok = false, error = `Failed to extract: {tarEntries}` }
	end

	-- npm wraps a package in one directory, normally `package/`.
	const files: { [string]: string } = {}
	const paths: { string } = {}
	for _, tarEntry in tarEntries do
		const path = tarEntry.path:match("^[^/]+/(.+)$")
		if path ~= nil then
			files[path] = tarEntry.content
			table.insert(paths, path)
		end
	end

	const projectJson = files["default.project.json"]
	if projectJson == nil then
		return { ok = false, error = "The package has no default.project.json, so it isn't a Roblox package" }
	end

	const sourcePath = readProjectSourcePath(projectJson)
	const _, folderName = nodeModulesPath(name)
	const entries: { buildTree.Entry } = {}
	for _, path in paths do
		const relativePath = relativeToSource(path, sourcePath)
		if relativePath ~= nil and relativePath ~= "" then
			table.insert(entries, { path = `{folderName}/{relativePath}`, content = files[path] })
		end
	end

	logger.debug(`extracted {#entries} entries from {label}, source path {sourcePath or "(none)"}`)

	const tree, pending = buildTree(entries, folderName)
	return { ok = true, tree = tree, pending = pending }
end

return downloadAndExtractAsync
