--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const coreTypes = require(StudioDiscover.Core.types)
const createLogger = require(StudioDiscover.Core.createLogger)
const packagesFolder = require(StudioDiscover.PesdeRegistry.packagesFolder)
const parseRootLink = require(StudioDiscover.PesdeRegistry.parseRootLink)
const realms = require(StudioDiscover.Core.realms)

const logger = createLogger.createLogger("pesde.installer.snapshot")

--[[
	Reads the roots installed in the place back out of the link modules in each
		realm's pesde packages folder, so the next resolve starts from what is there.
		Reading never creates a folder.
]]
const function snapshotRoots(): { coreTypes.RootRequest }
	const snapshots: { coreTypes.RootRequest } = {}

	for _, realm in realms do
		const folder = packagesFolder.find(realm)
		if folder == nil then
			continue
		end

		for _, child in folder:GetChildren() do
			if not child:IsA("ModuleScript") then
				continue
			end

			const target = parseRootLink(child.Source)
			if target == nil then
				logger.debug(`skip "{child.Name}" in {realm}: unparseable link`)
				continue
			end

			table.insert(snapshots, {
				scope = target.scope,
				name = target.name,
				version = target.version,
				requestRealm = realm,
				alias = child.Name,
			})
			logger.debug(`snapshot {target.scope}/{target.name}@{target.version} alias={child.Name} realm={realm}`)
		end
	end

	logger.info(`snapshot found {#snapshots} existing pesde root(s)`)
	return snapshots
end

return snapshotRoots
