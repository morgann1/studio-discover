--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local createLogger = require(StudioDiscover.Source.Util.createLogger)

local buildPackageLink = require(StudioDiscover.Source.Installer.Pesde.buildPackageLink)
local containerName = require(StudioDiscover.Source.Installer.Pesde.containerName)
local downloadAndExtractAsync = require(StudioDiscover.Source.Installer.Pesde.downloadAndExtractAsync)
local extractExports = require(StudioDiscover.Source.Installer.Pesde.extractExports)
local foldersModule = require(StudioDiscover.Source.Installer.Pesde.getPackagesFolder)
local setScriptSource = require(StudioDiscover.Source.Util.setScriptSource)
local types = require(StudioDiscover.Source.Installer.Pesde.types)

local logger = createLogger.createLogger("installer.pesdeApply")

local getPackagesFolder = foldersModule.getPackagesFolder
local getOrCreateContainer = foldersModule.getOrCreateContainer

type Realm = types.Realm
type Kind = types.Kind
type PesdeResolvedPackage = types.PesdeResolvedPackage
type ProgressCallback = types.ProgressCallback

type ExistingEntry = {
	outer: Folder,
	realm: Realm,
}

local function getOrCreateFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing ~= nil and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function destroyAllModuleScripts(parent: Instance)
	for _, child in parent:GetChildren() do
		if child:IsA("ModuleScript") then
			child:Destroy()
		end
	end
end

local function parentPackageRoot(container: Folder, pkg: PesdeResolvedPackage, tree: Instance): (Folder, Instance)
	if pkg.kind == "wally" then
		local outerName = containerName.formatWallyName(pkg.scope, pkg.name, pkg.version)
		local outer = getOrCreateFolder(container, outerName)
		for _, child in outer:GetChildren() do
			child:Destroy()
		end
		tree.Parent = outer
		return outer, tree
	end

	local outerName = containerName.formatPesdeName(pkg.scope, pkg.name)
	local outer = getOrCreateFolder(container, outerName)
	local version = getOrCreateFolder(outer, pkg.version)
	for _, child in version:GetChildren() do
		child:Destroy()
	end
	tree.Parent = version
	return outer, tree
end

local function snapshotExisting(): { [string]: ExistingEntry }
	local existing: { [string]: ExistingEntry } = {}
	for _, realm: Realm in { "shared", "server" } :: { Realm } do
		local packagesFolder = getPackagesFolder(realm)
		local container = packagesFolder:FindFirstChild(foldersModule.PACKAGES_CONTAINER_NAME)
		if container == nil then
			continue
		end
		for _, outer in container:GetChildren() do
			if not outer:IsA("Folder") then
				continue
			end
			local packageId = outer:GetAttribute("PackageId")
			if typeof(packageId) ~= "string" then
				continue
			end
			existing[packageId] = {
				outer = outer,
				realm = realm,
			}
		end
	end
	return existing
end

local function applyAsync(
	resolved: { [string]: PesdeResolvedPackage },
	rootAliases: { [string]: string },
	onProgress: ProgressCallback?
): { string }
	local failures: { string } = {}

	for _, realm: Realm in { "shared", "server" } :: { Realm } do
		local packagesFolder = getPackagesFolder(realm)
		destroyAllModuleScripts(packagesFolder)
	end

	local existing = snapshotExisting()

	for packageId, entry in existing do
		local pkg = resolved[packageId]
		if pkg == nil or pkg.realm ~= entry.realm then
			logger.debug(`drop {packageId} (realm={entry.realm})`)
			entry.outer:Destroy()
			existing[packageId] = nil
		end
	end

	for packageId, pkg in resolved do
		local packagesFolder = getPackagesFolder(pkg.realm)
		local container = getOrCreateContainer(packagesFolder)

		if existing[packageId] ~= nil then
			local outer = existing[packageId].outer
			for _, child in outer:GetDescendants() do
				if child:IsA("ModuleScript") and child:GetAttribute("PesdeLink") == true then
					child:Destroy()
				end
			end
			logger.debug(`reuse {packageId}`)
			continue
		end

		if onProgress ~= nil then
			onProgress(`Downloading {pkg.scope}/{pkg.name}@{pkg.version}...`)
		end
		logger.info(`downloading {packageId}`)

		local target: "roblox" | "roblox_server" = if pkg.realm == "server" then "roblox_server" else "roblox"
		local tree, pending, extractedLibPath, err = downloadAndExtractAsync(pkg.scope, pkg.name, pkg.version, target)
		if tree == nil then
			logger.warn(`download failed for {packageId}: {err}`)
			table.insert(failures, `{packageId}: {err}`)
			continue
		end

		if extractedLibPath ~= nil then
			pkg.libPath = extractedLibPath
		end

		local outer = parentPackageRoot(container, pkg, tree)
		outer:SetAttribute("PackageId", packageId)
		outer:SetAttribute("Kind", pkg.kind)
		if pkg.libPath ~= nil then
			outer:SetAttribute("LibPath", pkg.libPath)
		end

		local sourceFailure: string? = nil
		for _, item in pending :: { any } do
			local ok, sourceErr = setScriptSource(item.script, item.content)
			if not ok then
				sourceFailure = `{item.path}: {sourceErr}`
				break
			end
		end
		if sourceFailure ~= nil then
			logger.warn(`source write failed for {packageId}: {sourceFailure}`)
			table.insert(failures, `{packageId}: {sourceFailure}`)
			outer:Destroy()
		end
	end

	for _, pkg in resolved do
		if pkg.libPath ~= nil then
			continue
		end
		local packagesFolder = getPackagesFolder(pkg.realm)
		local container = packagesFolder:FindFirstChild(foldersModule.PACKAGES_CONTAINER_NAME)
		if container == nil then
			continue
		end
		local outerName = if pkg.kind == "wally"
			then containerName.formatWallyName(pkg.scope, pkg.name, pkg.version)
			else containerName.formatPesdeName(pkg.scope, pkg.name)
		local outer = container:FindFirstChild(outerName)
		if outer == nil then
			continue
		end
		local stored = outer:GetAttribute("LibPath")
		if typeof(stored) == "string" then
			pkg.libPath = stored
		end
	end

	local typeExportsByPackageId: { [string]: { string } } = {}
	for packageId, pkg in resolved do
		local packagesFolder = getPackagesFolder(pkg.realm)
		local container = packagesFolder:FindFirstChild(foldersModule.PACKAGES_CONTAINER_NAME)
		if container == nil then
			continue
		end
		local outerName = if pkg.kind == "wally"
			then containerName.formatWallyName(pkg.scope, pkg.name, pkg.version)
			else containerName.formatPesdeName(pkg.scope, pkg.name)
		local outer = container:FindFirstChild(outerName)
		if outer == nil then
			continue
		end
		local innerParent: Instance
		if pkg.kind == "wally" then
			innerParent = outer
		else
			local versionFolder = outer:FindFirstChild(pkg.version)
			if versionFolder == nil then
				continue
			end
			innerParent = versionFolder
		end
		local current = innerParent:FindFirstChild(pkg.name) :: any
		if current == nil then
			continue
		end
		for _, segment in buildPackageLink.libPathSegments(pkg.libPath) do
			current = current:FindFirstChild(segment) :: any
			if current == nil then
				break
			end
		end
		if current ~= nil and current:IsA("ModuleScript") then
			typeExportsByPackageId[packageId] = extractExports(current.Source)
		end
	end

	for packageId, pkg in resolved do
		if resolved[packageId] == nil then
			continue
		end
		local packagesFolder = getPackagesFolder(pkg.realm)
		local container = packagesFolder:FindFirstChild(foldersModule.PACKAGES_CONTAINER_NAME) :: Folder?
		if container == nil then
			continue
		end

		local outerName = if pkg.kind == "wally"
			then containerName.formatWallyName(pkg.scope, pkg.name, pkg.version)
			else containerName.formatPesdeName(pkg.scope, pkg.name)
		local outer = container:FindFirstChild(outerName) :: Folder?
		if outer == nil then
			continue
		end

		local innerParent: Instance
		if pkg.kind == "wally" then
			innerParent = outer
		else
			local versionFolder = outer:FindFirstChild(pkg.version)
			if versionFolder == nil then
				continue
			end
			innerParent = versionFolder
		end

		local root = innerParent:FindFirstChild(pkg.name)
		if root == nil then
			continue
		end

		local linkerParent = getOrCreateFolder(root, "roblox_packages")
		for _, dep in pkg.dependencies do
			local depPkg = resolved[dep.packageId]
			if depPkg == nil then
				continue
			end
			local build = buildPackageLink.buildTransitiveLink(
				pkg.kind,
				dep.alias,
				depPkg.scope,
				depPkg.name,
				depPkg.version,
				depPkg.libPath,
				depPkg.kind,
				typeExportsByPackageId[dep.packageId]
			)
			build.link:SetAttribute("PesdeLink", true)
			build.link.Parent = linkerParent
			local ok, linkErr = setScriptSource(build.link, build.source)
			if not ok then
				logger.warn(`link source write failed for {packageId} -> {dep.packageId}: {linkErr}`)
				build.link:Destroy()
			end
		end
	end

	for packageId, alias in rootAliases do
		local pkg = resolved[packageId]
		if pkg == nil then
			continue
		end
		local packagesFolder = getPackagesFolder(pkg.realm)
		local build = buildPackageLink.buildTopLevelLink(
			alias,
			pkg.scope,
			pkg.name,
			pkg.version,
			pkg.libPath,
			pkg.kind,
			typeExportsByPackageId[packageId]
		)
		build.link.Parent = packagesFolder
		local ok, linkErr = setScriptSource(build.link, build.source)
		if not ok then
			logger.warn(`root link source write failed for {packageId}: {linkErr}`)
			build.link:Destroy()
		end
	end

	return failures
end

return applyAsync
