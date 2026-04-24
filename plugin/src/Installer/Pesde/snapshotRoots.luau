--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local createLogger = require(StudioDiscover.Source.Util.createLogger)
local foldersModule = require(StudioDiscover.Source.Installer.Pesde.getPackagesFolder)
local types = require(StudioDiscover.Source.Installer.Pesde.types)

local logger = createLogger.createLogger("pesde.installer.snapshot")

local findPackagesFolder = foldersModule.findPackagesFolder

type Realm = types.Realm
type Kind = types.Kind

export type PesdeRootSnapshot = {
	scope: string,
	name: string,
	version: string,
	realm: Realm,
	kind: Kind,
	alias: string,
}

local function parseLinkSource(source: string): (string?, string?, string?, Kind?)
	local pathBody = source:match('require%("%./%.pesde/([^"]+)"%)')
	if pathBody == nil then
		return nil, nil, nil, nil
	end
	local outer = pathBody:match("^([^/]+)/")
	if outer == nil then
		return nil, nil, nil, nil
	end

	if outer:find("+", 1, true) then
		local scope, name = outer:match("^(.+)%+(.+)$")
		if scope == nil or name == nil then
			return nil, nil, nil, nil
		end
		local version = pathBody:match("^[^/]+/([^/]+)/")
		if version == nil then
			return nil, nil, nil, nil
		end
		return scope, name, version, "pesde"
	end

	if outer:find("@", 1, true) then
		local scopeName, version = outer:match("^(.+)@(.+)$")
		if scopeName == nil or version == nil then
			return nil, nil, nil, nil
		end
		local scope, name = scopeName:match("^(.+)_(.+)$")
		if scope == nil or name == nil then
			return nil, nil, nil, nil
		end
		return scope, name, version, "wally"
	end

	return nil, nil, nil, nil
end

local function snapshotRoots(): { PesdeRootSnapshot }
	local snapshots: { PesdeRootSnapshot } = {}

	for _, realm: Realm in { "shared", "server" } :: { Realm } do
		local packagesFolder = findPackagesFolder(realm)
		if packagesFolder == nil then
			continue
		end
		for _, child in packagesFolder:GetChildren() do
			if not child:IsA("ModuleScript") then
				continue
			end
			local scope, name, version, kind = parseLinkSource(child.Source)
			if scope == nil or name == nil or version == nil or kind == nil then
				logger.debug(`skip "{child.Name}" in {realm}: unparseable link`)
				continue
			end
			table.insert(snapshots, {
				scope = scope :: string,
				name = name :: string,
				version = version :: string,
				realm = realm,
				kind = kind :: Kind,
				alias = child.Name,
			})
			logger.debug(`snapshot {scope}/{name}@{version} alias={child.Name} realm={realm} kind={kind}`)
		end
	end

	logger.info(`snapshot found {#snapshots} existing pesde root(s)`)
	return snapshots
end

return snapshotRoots
