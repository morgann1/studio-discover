--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const buildPackageLink = require(StudioDiscover.Libraries.WallyRegistry.buildPackageLink)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const downloadAndExtractAsync = require(StudioDiscover.Libraries.WallyRegistry.downloadAndExtractAsync)
const parseLink = require(StudioDiscover.Libraries.PackageTypes.parseLink)
const packagesFolder = require(StudioDiscover.Libraries.WallyRegistry.packagesFolder)
const processLinkAsync = require(StudioDiscover.Libraries.PackageTypes.processLinkAsync)
const realms = require(StudioDiscover.Libraries.Core.realms)
const setScriptSourceAsync = require(StudioDiscover.Libraries.Core.setScriptSourceAsync)
const types = require(StudioDiscover.Libraries.WallyRegistry.types)
const writePendingSourcesAsync = require(StudioDiscover.Libraries.Core.writePendingSourcesAsync)

const logger = createLogger.createLogger("wally.installer.apply")

type InstalledPackage = {
	read folder: Folder,
	read realm: coreTypes.Realm,
}

-- The ModuleScript a link requires inside the package's folder, which is the tree root for most packages.
const function getModuleName(tree: Instance, fallbackName: string): string
	if tree:IsA("ModuleScript") then
		return tree.Name
	end

	for _, child in tree:GetChildren() do
		if child:IsA("ModuleScript") then
			return child.Name
		end
	end

	return fallbackName
end

const function placeTreeInFolder(tree: Instance, folder: Folder)
	if tree:IsA("ModuleScript") then
		tree.Parent = folder
		return
	end

	for _, child in tree:GetChildren() do
		child.Parent = folder
	end
	tree:Destroy()
end

-- The package folders already under each realm's `_Index`, keyed by their id.
const function findInstalledPackages(): { [string]: InstalledPackage? }
	const installed: { [string]: InstalledPackage? } = {}

	for _, realm in realms do
		const index = packagesFolder.findIndex(realm)
		if index == nil then
			continue
		end

		for _, child in index:GetChildren() do
			if child:IsA("Folder") then
				installed[child.Name] = { folder = child, realm = realm }
			end
		end
	end

	return installed
end

-- Parents a link and writes its source, then re-exports its target's types. A link that cannot be written is dropped.
const function writeLinkAsync(build: buildPackageLink.LinkBuild, parent: Instance, label: string)
	-- The link takes its alias, so anything already holding that name goes.
	const existing = parent:FindFirstChild(build.link.Name)
	if existing ~= nil then
		existing:Destroy()
	end

	build.link.Parent = parent

	const ok, err = setScriptSourceAsync(build.link, build.source)
	if not ok then
		logger.warn(`link source write failed for {label}: {err}`)
		build.link:Destroy()
		return
	end

	processLinkAsync(build.link)
end

--[[
	Writes a resolved graph into the place: every package under its realm's
		`_Index`, the links between them, and an alias in `Packages` for each root.

	Packages already installed at the same id and realm are kept and only relinked.
		Anything else under `_Index` is removed. Returns the non-fatal failures, each
		prefixed with the package it came from. Run it inside a ChangeHistory
		recording.
]]
const function applyAsync(
	resolved: { [string]: types.ResolvedPackage },
	rootAliases: { [string]: string },
	onProgress: coreTypes.ProgressCallback?
): { string }
	const failures: { string } = {}
	const packageFolders: { [string]: Folder? } = {}
	const moduleNames: { [string]: string? } = {}

	-- Root links are rewritten from `rootAliases` at the end. Any other module in the folder is left alone.
	for _, realm in realms do
		const folder = packagesFolder.find(realm)
		if folder == nil then
			continue
		end

		for _, child in folder:GetChildren() do
			if child:IsA("ModuleScript") and parseLink(child.Source) ~= nil then
				child:Destroy()
			end
		end
	end

	for id, installed in findInstalledPackages() do
		const resolvedPackage = resolved[id]
		if resolvedPackage == nil or resolvedPackage.realm ~= installed.realm then
			logger.debug(`drop {id} (realm={installed.realm})`)
			installed.folder:Destroy()
			continue
		end

		for _, child in installed.folder:GetChildren() do
			if child:IsA("ModuleScript") and parseLink(child.Source) ~= nil then
				child:Destroy()
			end
		end

		const moduleName = installed.folder:GetAttribute("ModuleName")
		packageFolders[id] = installed.folder
		moduleNames[id] = if typeof(moduleName) == "string" then moduleName else resolvedPackage.name
		logger.debug(`reuse existing {id} (ModuleName={moduleNames[id]})`)
	end

	for id, resolvedPackage in resolved do
		if packageFolders[id] ~= nil then
			continue
		end

		const label = `{resolvedPackage.scope}/{resolvedPackage.name}@{resolvedPackage.version}`
		if onProgress ~= nil then
			onProgress(`Downloading {label}...`)
		end
		logger.info(`downloading {label}`)

		const extracted = downloadAndExtractAsync(resolvedPackage.scope, resolvedPackage.name, resolvedPackage.version)
		if not extracted.ok then
			logger.warn(`download failed for {label}: {extracted.error}`)
			table.insert(failures, `{label}: {extracted.error}`)
			continue
		end

		const moduleName = getModuleName(extracted.tree, resolvedPackage.name)
		const folder = Instance.new("Folder")
		folder.Name = id
		folder:SetAttribute("ModuleName", moduleName)
		placeTreeInFolder(extracted.tree, folder)
		folder.Parent = packagesFolder.getIndex(resolvedPackage.realm)

		const sourceFailure = writePendingSourcesAsync(extracted.pending)
		if sourceFailure ~= nil then
			logger.warn(`source write failed for {label}: {sourceFailure}`)
			table.insert(failures, `{label}: {sourceFailure}`)
			folder:Destroy()
			continue
		end

		packageFolders[id] = folder
		moduleNames[id] = moduleName
	end

	for id, folder in packageFolders do
		const resolvedPackage = resolved[id]
		for _, dependency in resolvedPackage.dependencies do
			const target = resolved[dependency.packageId]
			if target == nil then
				continue
			end

			const build = buildPackageLink.buildSiblingPackageLink(
				dependency.alias,
				dependency.packageId,
				moduleNames[dependency.packageId] or target.name,
				resolvedPackage.realm,
				target.realm
			)
			writeLinkAsync(build, folder, `{id} -> {dependency.packageId}`)
		end
	end

	for id, alias in rootAliases do
		const resolvedPackage = resolved[id]
		if resolvedPackage == nil then
			continue
		end

		const build = buildPackageLink.buildRootPackageLink(alias, id, moduleNames[id] or resolvedPackage.name)
		writeLinkAsync(build, packagesFolder.get(resolvedPackage.realm), `root {id}`)
	end

	return failures
end

return applyAsync
