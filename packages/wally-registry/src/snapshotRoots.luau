--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const createLogger = require(StudioDiscover.Core.createLogger)
const packageId = require(StudioDiscover.WallyRegistry.packageId)
const parseLink = require(StudioDiscover.PackageTypes.parseLink)
const packagesFolder = require(StudioDiscover.WallyRegistry.packagesFolder)
const realms = require(StudioDiscover.Core.realms)
const types = require(StudioDiscover.Core.types)

const logger = createLogger.createLogger("wally.installer.snapshot")

--[[
	Reads the roots installed in the place back out of the link modules in each
		realm's packages folder, so the next resolve starts from what is there.
		Reading never creates a folder.
]]
const function snapshotRoots(): { types.RootRequest }
	const roots: { types.RootRequest } = {}

	for _, realm in realms do
		const folder = packagesFolder.find(realm)
		if folder == nil then
			continue
		end

		for _, child in folder:GetChildren() do
			if not child:IsA("ModuleScript") then
				continue
			end

			const link = parseLink(child.Source)
			if link == nil then
				logger.debug(`skip "{child.Name}" in {realm}: not a link`)
				continue
			end

			const existingId = link.packageId

			const scope, name, version = packageId.parse(existingId)
			if scope == nil or name == nil or version == nil then
				logger.warn(`could not parse package id "{existingId}" from link "{child.Name}"`)
				continue
			end

			table.insert(roots, {
				scope = scope,
				name = name,
				version = version,
				requestRealm = realm,
				alias = child.Name,
			})
			logger.debug(`snapshot {scope}/{name}@{version} alias={child.Name} realm={realm}`)
		end
	end

	logger.info(`snapshot found {#roots} existing root(s)`)
	return roots
end

return snapshotRoots
