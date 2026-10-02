--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const zzlib = require(StudioDiscover.Core.zzlib)

const asString = require(StudioDiscover.Core.asString)
const asTable = require(StudioDiscover.Core.asTable)
const buildTree = require(StudioDiscover.Core.buildTree)
const createLogger = require(StudioDiscover.Core.createLogger)
const downloadAsync = require(StudioDiscover.PesdeRegistry.Api.downloadAsync)
const parseTar = require(StudioDiscover.PesdeRegistry.parseTar)
const parseToml = require(StudioDiscover.Core.parseToml)
const types = require(StudioDiscover.PesdeRegistry.types)

const logger = createLogger.createLogger("pesde.installer.download")

-- `libPath` is the manifest's `target.lib`, when the archive's `pesde.toml` names one.
export type Extracted =
	{
		read ok: true,
		read tree: Instance,
		read pending: { buildTree.PendingSource },
		read libPath: string?,
	}
	| {
		read ok: false,
		read error: string,
	}

const function isGzip(data: string): boolean
	return #data >= 2 and string.byte(data, 1) == 0x1f and string.byte(data, 2) == 0x8b
end

const function extractLibPath(manifestSource: string): string?
	const ok, manifest = pcall(parseToml, manifestSource)
	const target = if ok then asTable(manifest.target) else nil
	return if target ~= nil then asString(target.lib) else nil
end

-- Downloads one package version for `target` and builds it into an unparented tree.
const function downloadAndExtractAsync(scope: string, name: string, version: string, target: types.Target): Extracted
	logger.debug(`fetch {scope}/{name}@{version} {target}`)

	const archive, err = downloadAsync(scope, name, version, target)
	if archive == nil then
		return { ok = false, error = `Failed to download: {err}` }
	end

	local tarData = archive
	if isGzip(archive) then
		const gunzipOk, result = pcall(zzlib.gunzip, archive)
		if not gunzipOk then
			logger.warn(`gunzip failed for {scope}/{name}@{version}: {result}`)
			return { ok = false, error = `Failed to decompress: {result}` }
		end

		tarData = result
	end

	const parseOk, tarEntries = pcall(parseTar, tarData)
	if not parseOk then
		logger.warn(`tar parse failed for {scope}/{name}@{version}: {tarEntries}`)
		return { ok = false, error = `Failed to extract: {tarEntries}` }
	end

	const entries: { buildTree.Entry } = {}
	local libPath: string? = nil
	for _, tarEntry in tarEntries do
		if tarEntry.path == "pesde.toml" then
			libPath = extractLibPath(tarEntry.content)
		end

		table.insert(entries, { path = `{name}/{tarEntry.path}`, content = tarEntry.content })
	end

	logger.debug(`extracted {#entries} entries from {scope}/{name}@{version}, libPath={libPath or "nil"}`)

	const tree, pending = buildTree(entries, name)
	return { ok = true, tree = tree, pending = pending, libPath = libPath }
end

return downloadAndExtractAsync
