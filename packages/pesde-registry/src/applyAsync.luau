--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const buildPackageLink = require(StudioDiscover.Libraries.PesdeRegistry.buildPackageLink)
const containerName = require(StudioDiscover.Libraries.PesdeRegistry.containerName)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const downloadAndExtractAsync = require(StudioDiscover.Libraries.PesdeRegistry.downloadAndExtractAsync)
const forwardTypes = require(StudioDiscover.Libraries.PackageTypes.forwardTypes)
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

type InstalledPackage = {
	read container: Folder,
	read realm: coreTypes.Realm,
}

-- The package containers already in each realm's `.pesde` index, keyed by the package id they were installed as.
const function findInstalledPackages(): { [string]: InstalledPackage? }
	const installed: { [string]: InstalledPackage? } = {}

	for _, realm in realms do
		const index = packagesFolder.findIndex(realm)
		if index == nil then
			continue
		end

		for _, container in index:GetChildren() do
			const id = container:GetAttribute("PackageId")
			if container:IsA("Folder") and typeof(id) == "string" then
				installed[id] = { container = container, realm = realm }
			end
		end
	end

	return installed
end

-- Puts a freshly built tree where the index expects it, replacing what was there, and returns its container.
const function placePackage(pkg: PesdeResolvedPackage, tree: Instance): Folder
	const index = packagesFolder.getIndex(pkg.realm)
	const container = getOrCreateFolder(index, containerName(pkg.scope, pkg.name))
	const parent = getOrCreateFolder(container, pkg.version)

	for _, child in parent:GetChildren() do
		child:Destroy()
	end
	tree.Parent = parent

	return container
end

const function findContainer(pkg: PesdeResolvedPackage): Instance?
	const index = packagesFolder.findIndex(pkg.realm)
	if index == nil then
		return nil
	end

	return index:FindFirstChild(containerName(pkg.scope, pkg.name))
end

-- The package's own root inside its container, under its version folder.
const function findPackageRoot(container: Instance, pkg: PesdeResolvedPackage): Instance?
	const parent = container:FindFirstChild(pkg.version)
	if parent == nil then
		return nil
	end

	return parent:FindFirstChild(pkg.name)
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

	Packages already installed under the same id and realm are kept and only
		relinked. Anything else in the index is removed. Sets `libPath` on `resolved`:
		from the archive's manifest when it names one, otherwise from what a kept
		package was installed with. Returns the non-fatal failures, each prefixed with
		the package it came from. Run it inside a ChangeHistory recording.
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

	const installed = findInstalledPackages()
	for id, existing in installed do
		const pkg = resolved[id]
		if pkg == nil or pkg.realm ~= existing.realm then
			logger.debug(`drop {id} (realm={existing.realm})`)
			existing.container:Destroy()
			installed[id] = nil
			continue
		end

		for _, descendant in existing.container:GetDescendants() do
			if descendant:IsA("ModuleScript") and descendant:GetAttribute("PesdeLink") == true then
				descendant:Destroy()
			end
		end
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

		const container = placePackage(pkg, extracted.tree)
		container:SetAttribute("PackageId", id)
		if pkg.libPath ~= nil then
			container:SetAttribute("LibPath", pkg.libPath)
		end

		const sourceFailure = writePendingSourcesAsync(extracted.pending)
		if sourceFailure ~= nil then
			logger.warn(`source write failed for {id}: {sourceFailure}`)
			table.insert(failures, `{id}: {sourceFailure}`)
			container:Destroy()
		end
	end

	const packageRoots: { [string]: Instance } = {}
	const typeExports: { [string]: { string }? } = {}
	for id, pkg in resolved do
		const container = findContainer(pkg)
		const root = if container ~= nil then findPackageRoot(container, pkg) else nil
		if container == nil or root == nil then
			continue
		end

		-- A kept package still knows the lib path it was installed with.
		const storedLibPath = container:GetAttribute("LibPath")
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
