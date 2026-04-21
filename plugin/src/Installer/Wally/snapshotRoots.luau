--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local createLogger = require(StudioDiscover.Source.Util.createLogger)
local foldersModule = require(StudioDiscover.Source.Installer.Wally.getPackagesFolder)
local packageId = require(StudioDiscover.Source.Installer.Wally.packageId)
local types = require(StudioDiscover.Source.Installer.types)

local logger = createLogger.createLogger("installer.snapshot")

local findPackagesFolder = foldersModule.findPackagesFolder

type Realm = types.Realm
type RootRequest = types.RootRequest

local function extractPackageIdFromLink(source: string): string?
	return source:match('%["([^"]+@[^"]+)"%]%["[^"]+"%]')
end

local function snapshotRoots(): { RootRequest }
	local roots: { RootRequest } = {}

	for _, realm: Realm in { "shared", "server" } :: { Realm } do
		local packagesFolder = findPackagesFolder(realm)
		if packagesFolder == nil then
			continue
		end
		for _, child in packagesFolder:GetChildren() do
			if not child:IsA("ModuleScript") then
				continue
			end
			local existingId = extractPackageIdFromLink(child.Source)
			if existingId == nil then
				logger.debug(`skip "{child.Name}" in {realm}: no package id in source`)
				continue
			end
			local scope, name, version = packageId.parse(existingId)
			if scope == nil or name == nil or version == nil then
				logger.warn(`could not parse package id "{existingId}" from link "{child.Name}"`)
				continue
			end
			table.insert(roots, {
				scope = scope :: string,
				name = name :: string,
				version = version :: string,
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
