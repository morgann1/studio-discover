--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const buildPackageLink = require(StudioDiscover.Libraries.PesdeRegistry.buildPackageLink)
const containerName = require(StudioDiscover.Libraries.PesdeRegistry.containerName)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const downloadAndExtractAsync = require(StudioDiscover.Libraries.PesdeRegistry.downloadAndExtractAsync)
const forwardTypes = require(StudioDiscover.Libraries.PesdeRegistry.forwardTypes)
const getOrCreateFolder = require(StudioDiscover.Libraries.Core.getOrCreateFolder)
const libPathSegments = require(StudioDiscover.Libraries.PesdeRegistry.libPathSegments)
const packagesFolder = require(StudioDiscover.Libraries.PesdeRegistry.packagesFolder)
const parseRootLink = require(StudioDiscover.Libraries.PesdeRegistry.parseRootLink)
const realms = require(StudioDiscover.Libraries.Core.realms)
const setScriptSourceAsync = require(StudioDiscover.Libraries.Core.setScriptSourceAsync)
const targetFromRealm = require(StudioDiscover.Libraries.PesdeRegistry.targetFromRealm)
const types = require(StudioDiscover.Libraries.PesdeRegistry.types)
const writePendingSourcesAsync = require(StudioDiscover.Libraries.Core.writePendingSourcesAsync)

const logger = createLogger.createLogger("pesde.installer.apply")

type PesdeResolvedPackage = types.PesdeResolvedPackage

--[[
	One version folder in a realm's `.pesde` index, and the package id it was
		installed as. `id` is nil for a folder that does not carry its own.
]]
type InstalledVersion = {
	read id: string?,
	read folder: Instance,
	read realm: coreTypes.Realm,
}

--[[
	A one-time migration for places installed before each version folder carried
		its own id. Those containers hold a single `PackageId` for the version placed
		last, and the last `LibPath` written, which is normally that version's. This
		moves the pair onto that version's folder and clears it from the container,
		so the first apply after the fix keeps that version instead of downloading it
		again. Any other version in the container stays without an id and is
		downloaded again.
]]
const function adoptContainerId(container: Instance)
	const id = container:GetAttribute("PackageId")
	if typeof(id) ~= "string" then
		return
	end

	const libPath = container:GetAttribute("LibPath")
	container:SetAttribute("PackageId", nil)
	container:SetAttribute("LibPath", nil)

	-- The id is `scope/name@version target`, and the version folder is named for the version.
	const version = id:match("@(%S+) %S+$")
	const versionFolder = if version ~= nil then container:FindFirstChild(version) else nil
	if versionFolder == nil or versionFolder:GetAttribute("PackageId") ~= nil then
		return
	end

	versionFolder:SetAttribute("PackageId", id)
	if typeof(libPath) == "string" then
		versionFolder:SetAttribute("LibPath", libPath)
	end
end

-- Every version folder in each realm's `.pesde` index, inside every container, after adopting a pre-fix container's id.
const function findInstalledVersions(): { InstalledVersion }
	const installed: { InstalledVersion } = {}

	for _, realm in realms do
		const index = packagesFolder.findIndex(realm)
		if index == nil then
			continue
		end

		for _, container in index:GetChildren() do
			if not container:IsA("Folder") then
				continue
			end

			adoptContainerId(container)

			for _, folder in container:GetChildren() do
				const id = folder:GetAttribute("PackageId")
				table.insert(installed, {
					id = if typeof(id) == "string" then id else nil,
					folder = folder,
					realm = realm,
				})
			end
		end
	end

	return installed
end

-- Removes one version folder, and its container once no other version is left in it.
const function destroyVersionFolder(folder: Instance)
	const container = folder.Parent
	folder:Destroy()

	if container ~= nil and #container:GetChildren() == 0 then
		container:Destroy()
	end
end

-- Puts a freshly built tree where the index expects it, replacing what was there, and returns its version folder.
const function placePackage(pkg: PesdeResolvedPackage, tree: Instance): Folder
	const index = packagesFolder.getIndex(pkg.realm)
	const container = getOrCreateFolder(index, containerName(pkg.scope, pkg.name))
	const versionFolder = getOrCreateFolder(container, pkg.version)

	for _, child in versionFolder:GetChildren() do
		child:Destroy()
	end
	tree.Parent = versionFolder

	return versionFolder
end

-- The folder a package's version lives in. It holds the package root and carries its `LibPath`.
const function findVersionFolder(pkg: PesdeResolvedPackage): Instance?
	const index = packagesFolder.findIndex(pkg.realm)
	const container = if index ~= nil then index:FindFirstChild(containerName(pkg.scope, pkg.name)) else nil
	return if container ~= nil then container:FindFirstChild(pkg.version) else nil
end

const function findLibModule(root: Instance, libPath: string?): ModuleScript?
	local current: Instance? = root
	for _, segment in libPathSegments(libPath) do
		if current == nil then
			return nil
		end

		current = current:FindFirstChild(segment)
	end

	if current ~= nil and current:IsA("ModuleScript") then
		return current
	end

	return nil
end

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
	end
end

--[[
	Writes a resolved graph into the place: every package in its realm's `.pesde`
		index, each package's `roblox_packages` links, and an alias in the realm's
		packages folder for each root.

	Each version folder tracks the package id and lib path it was installed with.
		Versions already installed under the same id and realm are kept and only
		relinked. Every other version folder is removed, then its container once it
		is empty.

	Sets `libPath` on `resolved`: from the archive's manifest when it names one,
		otherwise from what a kept package was installed with. Returns the non-fatal
		failures, each prefixed with the package it came from. Run it inside a
		ChangeHistory recording.
]]
const function applyAsync(
	resolved: { [string]: PesdeResolvedPackage },
	rootAliases: { [string]: string },
	onProgress: coreTypes.ProgressCallback?
): { string }
	const failures: { string } = {}

	-- Root links are rewritten from `rootAliases` at the end. Any other module in the folder is left alone.
	for _, realm in realms do
		const folder = packagesFolder.find(realm)
		if folder == nil then
			continue
		end

		for _, child in folder:GetChildren() do
			if child:IsA("ModuleScript") and parseRootLink(child.Source) ~= nil then
				child:Destroy()
			end
		end
	end

	-- A version folder without an id is not trusted. It is dropped, and downloaded again below if it is still resolved.
	const installed: { [string]: true? } = {}
	for _, existing in findInstalledVersions() do
		const id = existing.id
		const pkg = if id ~= nil then resolved[id] else nil
		if id == nil or pkg == nil or pkg.realm ~= existing.realm then
			logger.debug(`drop {existing.folder:GetFullName()} (id={id or "none"})`)
			destroyVersionFolder(existing.folder)
			continue
		end

		for _, descendant in existing.folder:GetDescendants() do
			if descendant:IsA("ModuleScript") and descendant:GetAttribute("PesdeLink") == true then
				descendant:Destroy()
			end
		end

		installed[id] = true
		logger.debug(`reuse {id}`)
	end

	for id, pkg in resolved do
		if installed[id] ~= nil then
			continue
		end

		if onProgress ~= nil then
			onProgress(`Downloading {pkg.scope}/{pkg.name}@{pkg.version}...`)
		end
		logger.info(`downloading {id}`)

		const extracted = downloadAndExtractAsync(pkg.scope, pkg.name, pkg.version, targetFromRealm(pkg.realm))
		if not extracted.ok then
			logger.warn(`download failed for {id}: {extracted.error}`)
			table.insert(failures, `{id}: {extracted.error}`)
			continue
		end

		if extracted.libPath ~= nil then
			pkg.libPath = extracted.libPath
		end

		const versionFolder = placePackage(pkg, extracted.tree)
		versionFolder:SetAttribute("PackageId", id)
		if pkg.libPath ~= nil then
			versionFolder:SetAttribute("LibPath", pkg.libPath)
		end

		const sourceFailure = writePendingSourcesAsync(extracted.pending)
		if sourceFailure ~= nil then
			logger.warn(`source write failed for {id}: {sourceFailure}`)
			table.insert(failures, `{id}: {sourceFailure}`)
			destroyVersionFolder(versionFolder)
		end
	end

	const packageRoots: { [string]: Instance } = {}
	const typeExports: { [string]: { string }? } = {}
	for id, pkg in resolved do
		const versionFolder = findVersionFolder(pkg)
		const root = if versionFolder ~= nil then versionFolder:FindFirstChild(pkg.name) else nil
		if versionFolder == nil or root == nil then
			continue
		end

		-- A kept package still knows the lib path it was installed with.
		const storedLibPath = versionFolder:GetAttribute("LibPath")
		if pkg.libPath == nil and typeof(storedLibPath) == "string" then
			pkg.libPath = storedLibPath
		end

		packageRoots[id] = root

		const libModule = findLibModule(root, pkg.libPath)
		if libModule ~= nil then
			typeExports[id] = forwardTypes(libModule.Source, "module")
		end
	end

	for id, root in packageRoots do
		const pkg = resolved[id]
		const linkParent = getOrCreateFolder(root, "roblox_packages")

		for _, dependency in pkg.dependencies do
			const target = resolved[dependency.packageId]
			if target == nil then
				continue
			end

			const build =
				buildPackageLink.buildTransitiveLink(dependency.alias, target, typeExports[dependency.packageId])
			build.link:SetAttribute("PesdeLink", true)
			writeLinkAsync(build, linkParent, `{id} -> {dependency.packageId}`)
		end
	end

	for id, alias in rootAliases do
		const pkg = resolved[id]
		if pkg == nil then
			continue
		end

		const build = buildPackageLink.buildTopLevelLink(alias, pkg, typeExports[id])
		writeLinkAsync(build, packagesFolder.get(pkg.realm), `root {id}`)
	end

	return failures
end

return applyAsync
