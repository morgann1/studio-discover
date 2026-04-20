--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local createLogger = require(StudioDiscover.Source.Util.createLogger)
local downloadAndExtractAsync = require(StudioDiscover.Source.Installer.downloadAndExtractAsync)
local foldersModule = require(StudioDiscover.Source.Installer.getPackagesFolder)
local linkModule = require(StudioDiscover.Source.Installer.buildPackageLink)
local processPackageTypes = require(StudioDiscover.Source.Installer.processPackageTypes)
local types = require(StudioDiscover.Source.Installer.types)

local logger = createLogger.createLogger("installer.apply")

local buildSiblingPackageLink = linkModule.buildSiblingPackageLink
local buildRootPackageLink = linkModule.buildRootPackageLink
local getPackagesFolder = foldersModule.getPackagesFolder
local getOrCreateIndex = foldersModule.getOrCreateIndex

type Realm = "shared" | "server"
type ResolvedPackage = types.ResolvedPackage
type ProgressCallback = types.ProgressCallback

type ExistingEntry = {
	folder: Folder,
	realm: Realm,
}

local function isLinkModule(source: string): boolean
	return source:match('%["([^"]+@[^"]+)"%]') ~= nil
end

local function getModuleName(tree: Instance, fallbackName: string): string
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

local function placeTreeInFolder(tree: Instance, folder: Folder)
	if tree:IsA("ModuleScript") then
		tree.Parent = folder
		return
	end
	for _, child in tree:GetChildren() do
		child.Parent = folder
	end
	tree:Destroy()
end

local function applyAsync(
	resolved: { [string]: ResolvedPackage },
	rootAliases: { [string]: string },
	onProgress: ProgressCallback?
): { string }
	local failures: { string } = {}
	local moduleNames: { [string]: string } = {}

	for _, realmName: Realm in { "shared", "server" } :: { Realm } do
		local packagesFolder = getPackagesFolder(realmName)
		for _, child in packagesFolder:GetChildren() do
			if child:IsA("ModuleScript") then
				child:Destroy()
			end
		end
	end

	local existingByPackageId: { [string]: ExistingEntry } = {}
	for _, realmName: Realm in { "shared", "server" } :: { Realm } do
		local packagesFolder = getPackagesFolder(realmName)
		local indexFolder = packagesFolder:FindFirstChild("_Index")
		if indexFolder ~= nil then
			for _, child in indexFolder:GetChildren() do
				if child:IsA("Folder") then
					existingByPackageId[child.Name] = {
						folder = child,
						realm = realmName,
					}
				end
			end
		end
	end

	for packageId, existing in existingByPackageId do
		local resolvedPackage = resolved[packageId]
		if resolvedPackage == nil then
			logger.debug(`drop orphan {packageId} (realm={existing.realm})`)
			existing.folder:Destroy()
			existingByPackageId[packageId] = nil
		elseif resolvedPackage.realm ~= existing.realm then
			logger.debug(`drop {packageId}: realm changed {existing.realm} -> {resolvedPackage.realm}`)
			existing.folder:Destroy()
			existingByPackageId[packageId] = nil
		end
	end

	for packageId, resolvedPackage in resolved do
		local packagesFolder = getPackagesFolder(resolvedPackage.realm)
		local indexFolder = getOrCreateIndex(packagesFolder)

		local existing = existingByPackageId[packageId]
		if existing ~= nil then
			local moduleName = existing.folder:GetAttribute("ModuleName")
			moduleNames[packageId] = if typeof(moduleName) == "string" then moduleName else resolvedPackage.name
			logger.debug(`reuse existing {packageId} (ModuleName={moduleNames[packageId]})`)

			for _, child in existing.folder:GetChildren() do
				if child:IsA("ModuleScript") and isLinkModule(child.Source) then
					child:Destroy()
				end
			end
			continue
		end

		if onProgress ~= nil then
			onProgress(`Downloading {resolvedPackage.scope}/{resolvedPackage.name}@{resolvedPackage.version}...`)
		end
		logger.info(`downloading {resolvedPackage.scope}/{resolvedPackage.name}@{resolvedPackage.version}`)

		local tree, err = downloadAndExtractAsync(resolvedPackage.scope, resolvedPackage.name, resolvedPackage.version)
		if tree == nil then
			logger.warn(
				`download failed for {resolvedPackage.scope}/{resolvedPackage.name}@{resolvedPackage.version}: {err}`
			)
			table.insert(failures, `{resolvedPackage.scope}/{resolvedPackage.name}@{resolvedPackage.version}: {err}`)
			continue
		end
		logger.debug(`downloaded {resolvedPackage.scope}/{resolvedPackage.name}@{resolvedPackage.version}`)

		local moduleName = getModuleName(tree, resolvedPackage.name)
		moduleNames[packageId] = moduleName

		local packageFolder = Instance.new("Folder")
		packageFolder.Name = packageId
		packageFolder:SetAttribute("ModuleName", moduleName)
		placeTreeInFolder(tree, packageFolder)
		packageFolder.Parent = indexFolder
	end

	for packageId, resolvedPackage in resolved do
		local packagesFolder = getPackagesFolder(resolvedPackage.realm)
		local indexFolder = getOrCreateIndex(packagesFolder)
		local packageFolder = indexFolder:FindFirstChild(packageId) :: Folder?
		if packageFolder == nil then
			continue
		end

		for _, dep in resolvedPackage.dependencies do
			local depResolved = resolved[dep.packageId]
			if depResolved == nil then
				continue
			end
			local dependencyModuleName = moduleNames[dep.packageId] or depResolved.name
			local link = buildSiblingPackageLink(
				dep.alias,
				dep.packageId,
				dependencyModuleName,
				resolvedPackage.realm,
				depResolved.realm
			)
			link.Parent = packageFolder
			processPackageTypes.processLink(link)
		end
	end

	for packageId, alias in rootAliases do
		local resolvedPackage = resolved[packageId]
		if resolvedPackage == nil then
			continue
		end
		local packagesFolder = getPackagesFolder(resolvedPackage.realm)
		local moduleName = moduleNames[packageId] or resolvedPackage.name
		local rootLink =
			buildRootPackageLink(alias, packageId, moduleName, resolvedPackage.realm, resolvedPackage.realm)
		rootLink.Parent = packagesFolder
		processPackageTypes.processLink(rootLink)
	end

	return failures
end

return applyAsync
