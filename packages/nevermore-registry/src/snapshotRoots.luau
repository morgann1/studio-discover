--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const coreTypes = require(StudioDiscover.Libraries.Core.types)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const gameFolder = require(StudioDiscover.Libraries.NevermoreRegistry.gameFolder)
const listNodeModules = require(StudioDiscover.Libraries.NevermoreRegistry.listNodeModules)
const packageAttributes = require(StudioDiscover.Libraries.NevermoreRegistry.packageAttributes)
const parsePackageId = require(StudioDiscover.Libraries.NevermoreRegistry.parsePackageId)
const splitNpmName = require(StudioDiscover.Libraries.NevermoreRegistry.splitNpmName)

const logger = createLogger.createLogger("nevermore.installer.snapshot")

--[[
	Reads the roots installed in the place back out of the top of `node_modules`, so
		the next resolve starts from what is there. Reading never creates a folder.

	Nevermore has no realms or aliases. The loader finds modules by name and
		replicates them by folder, so every root reads as shared and goes by its
		package name.
]]
const function snapshotRoots(): { coreTypes.RootRequest }
	const snapshots: { coreTypes.RootRequest } = {}

	const folder = gameFolder.findNodeModules()
	if folder == nil then
		return snapshots
	end

	for _, instance in listNodeModules(folder) do
		const id = instance:GetAttribute(packageAttributes.PACKAGE_ID)
		if instance:GetAttribute(packageAttributes.ROOT) ~= true or typeof(id) ~= "string" then
			continue
		end

		const fullName, version = parsePackageId(id)
		const scope, name = splitNpmName(fullName or "")
		if scope == nil or name == nil or version == nil then
			logger.debug(`skip "{instance:GetFullName()}": unreadable package id "{id}"`)
			continue
		end

		const root: coreTypes.RootRequest = {
			scope = scope,
			name = name,
			version = version,
			requestRealm = "shared",
			alias = name,
		}
		table.insert(snapshots, root)
	end

	table.sort(snapshots, function(a: coreTypes.RootRequest, b: coreTypes.RootRequest)
		return a.name < b.name
	end)

	logger.info(`snapshot found {#snapshots} existing Nevermore root(s)`)
	return snapshots
end

return snapshotRoots
