--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const coreTypes = require(StudioDiscover.Libraries.Core.types)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const downloadAndExtractAsync = require(StudioDiscover.Libraries.NevermoreRegistry.downloadAndExtractAsync)
const gameFolder = require(StudioDiscover.Libraries.NevermoreRegistry.gameFolder)
const getOrCreateFolder = require(StudioDiscover.Libraries.Core.getOrCreateFolder)
const layoutPackages = require(StudioDiscover.Libraries.NevermoreRegistry.layoutPackages)
const listNodeModules = require(StudioDiscover.Libraries.NevermoreRegistry.listNodeModules)
const nodeModulesPath = require(StudioDiscover.Libraries.NevermoreRegistry.nodeModulesPath)
const packageAttributes = require(StudioDiscover.Libraries.NevermoreRegistry.packageAttributes)
const parsePackageId = require(StudioDiscover.Libraries.NevermoreRegistry.parsePackageId)
const setUpGameAsync = require(StudioDiscover.Libraries.NevermoreRegistry.setUpGameAsync)
const types = require(StudioDiscover.Libraries.NevermoreRegistry.types)
const writePendingSourcesAsync = require(StudioDiscover.Libraries.Core.writePendingSourcesAsync)

const logger = createLogger.createLogger("nevermore.installer.apply")

type Placement = types.Placement

const function packageIdOf(instance: Instance): string?
	const id = instance:GetAttribute(packageAttributes.PACKAGE_ID)
	return if typeof(id) == "string" then id else nil
end

-- A package's own `node_modules`, where the packages only it needs nest.
const function findNested(instance: Instance): Folder?
	const nested = instance:FindFirstChild("node_modules")
	return if nested ~= nil and nested:IsA("Folder") then nested else nil
end

-- One installed copy of every package id in the tree under `folder`, so a package that moves is copied, not downloaded.
const function indexInstalled(folder: Instance, installed: { [string]: Instance })
	for _, instance in listNodeModules(folder) do
		const id = packageIdOf(instance)
		if id ~= nil and installed[id] == nil then
			installed[id] = instance
		end

		const nested = findNested(instance)
		if nested ~= nil then
			indexInstalled(nested, installed)
		end
	end
end

-- The package ids that need a new copy somewhere under `folder`, because the copy there is another version or missing.
const function collectNeeded(folder: Instance?, placements: { [string]: Placement }, needed: { [string]: true? })
	const installed = if folder ~= nil then listNodeModules(folder) else {}

	for name, placement in placements do
		const instance = installed[name]
		if instance ~= nil and packageIdOf(instance) == placement.packageId then
			collectNeeded(findNested(instance), placement.children, needed)
		else
			needed[placement.packageId] = true
			collectNeeded(nil, placement.children, needed)
		end
	end
end

--[[
	A copy of each needed package to clone into place, without the place's own
		`node_modules` nested in it. An installed copy is reused, and anything else is
		downloaded. A package that fails to download or write is missing from the
		result, and its failure is added to `failures`.
]]
const function buildTemplatesAsync(
	needed: { [string]: true? },
	installed: { [string]: Instance },
	failures: { string },
	onProgress: coreTypes.ProgressCallback?
): { [string]: Instance }
	const ids: { string } = {}
	for id in needed do
		table.insert(ids, id)
	end
	table.sort(ids)

	const templates: { [string]: Instance } = {}
	for _, id in ids do
		const existing = installed[id]
		if existing ~= nil then
			const template = existing:Clone()
			const nested = findNested(template)
			if nested ~= nil then
				nested:Destroy()
			end

			templates[id] = template
			continue
		end

		const name, version = parsePackageId(id)
		if name == nil or version == nil then
			table.insert(failures, `{id}: not a package id`)
			continue
		end

		if onProgress ~= nil then
			onProgress(`Downloading {id}...`)
		end
		logger.info(`downloading {id}`)

		const extracted = downloadAndExtractAsync(name, version)
		if not extracted.ok then
			logger.warn(`download failed for {id}: {extracted.error}`)
			table.insert(failures, `{id}: {extracted.error}`)
			continue
		end

		const sourceFailure = writePendingSourcesAsync(extracted.pending)
		if sourceFailure ~= nil then
			logger.warn(`source write failed for {id}: {sourceFailure}`)
			table.insert(failures, `{id}: {sourceFailure}`)
			extracted.tree:Destroy()
			continue
		end

		templates[id] = extracted.tree
	end

	return templates
end

--[[
	Makes `folder` hold exactly the packages in `placements`, recursing into each
		package's own `node_modules`. A copy already at the right version stays.
		Discover's other copies go, and anything without a package id stays unless a
		package needs its name.
]]
const function reconcile(
	folder: Folder,
	placements: { [string]: Placement },
	templates: { [string]: Instance },
	rootIds: { [string]: true? }?
)
	const kept: { [string]: Instance } = {}
	for name, instance in listNodeModules(folder) do
		const id = packageIdOf(instance)
		const placement = placements[name]

		if placement ~= nil and id == placement.packageId then
			kept[name] = instance
		elseif placement ~= nil or id ~= nil then
			instance:Destroy()
		end
	end

	for name, placement in placements do
		local instance = kept[name]
		if instance == nil then
			const template = templates[placement.packageId]
			if template == nil then
				continue
			end

			const scope, folderName = nodeModulesPath(name)
			instance = template:Clone()
			instance.Name = folderName
			instance.Parent = if scope ~= nil then getOrCreateFolder(folder, scope) else folder
		end

		const isRoot = rootIds ~= nil and rootIds[placement.packageId] ~= nil
		instance:SetAttribute(packageAttributes.PACKAGE_ID, placement.packageId)
		instance:SetAttribute(packageAttributes.ROOT, if isRoot then true else nil)

		const nested = findNested(instance)
		if next(placement.children) ~= nil then
			reconcile(nested or getOrCreateFolder(instance, "node_modules"), placement.children, templates, nil)
		elseif nested ~= nil then
			reconcile(nested, {}, templates, nil)
			if #nested:GetChildren() == 0 then
				nested:Destroy()
			end
		end
	end

	for _, child in folder:GetChildren() do
		if string.sub(child.Name, 1, 1) == "@" and child:IsA("Folder") and #child:GetChildren() == 0 then
			child:Destroy()
		end
	end
end

--[[
	Writes a resolved graph into the place's `node_modules`, laid out as npm installs
		it, and marks each root. The first install also sets the game up for the
		loader, as `nevermore init` does.

	Packages already at the right version and place are kept. One that moves is
		copied from where it was, and anything else is downloaded. Returns the
		non-fatal failures, each prefixed with the package it came from. Run it
		inside a ChangeHistory recording.
]]
const function applyAsync(
	resolved: { [string]: types.NevermoreResolvedPackage },
	rootIds: { string },
	onProgress: coreTypes.ProgressCallback?
): { string }
	const placements, failures = layoutPackages(resolved, rootIds)

	const installed: { [string]: Instance } = {}
	const existingFolder = gameFolder.findNodeModules()
	if existingFolder ~= nil then
		indexInstalled(existingFolder, installed)
	end

	-- Uninstalling the last root empties `node_modules` and leaves the game folder to the user.
	if next(placements) == nil then
		if existingFolder ~= nil then
			reconcile(existingFolder, {}, {}, nil)
		end

		return failures
	end

	if gameFolder.find() == nil then
		const setUpError = setUpGameAsync()
		if setUpError ~= nil then
			table.insert(failures, `setup: {setUpError}`)
		end
	end

	const needed: { [string]: true? } = {}
	collectNeeded(existingFolder, placements, needed)
	const templates = buildTemplatesAsync(needed, installed, failures, onProgress)

	const rootSet: { [string]: true? } = {}
	for _, rootId in rootIds do
		rootSet[rootId] = true
	end

	reconcile(gameFolder.getNodeModules(), placements, templates, rootSet)

	for _, template in templates do
		template:Destroy()
	end

	return failures
end

return applyAsync
