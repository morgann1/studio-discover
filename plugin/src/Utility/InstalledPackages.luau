local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

export type InstalledPackage = {
	scope: string,
	name: string,
	version: string,
	realm: "shared" | "server",
	packageId: string, -- e.g. "jsdotlua_react@17.2.1"
	indexFolder: Folder,
	aliasLink: ModuleScript, -- The top-level alias ModuleScript the user installed
}

local InstalledPackages = {}

local function parsePackageId(packageId: string): (string?, string?, string?)
	local scopeAndName, version = packageId:match("^(.+)@(.+)$")
	if not scopeAndName then
		return nil, nil, nil
	end
	local scope, name = scopeAndName:match("^(.+)_(.+)$")
	if not scope then
		return nil, nil, nil
	end
	return scope, name, version
end

-- Extract "scope_name@version" from an alias link's Source:
--   return require(script.Parent._Index["jsdotlua_react@17.2.1"]["react"])
local function extractPackageId(source: string): string?
	return source:match('_Index%["([^"]+)"%]')
end

local function scanRealm(packagesFolder: Folder?, realm: "shared" | "server", out: { InstalledPackage })
	if not packagesFolder then
		return
	end
	local indexFolder = packagesFolder:FindFirstChild("_Index")
	if not indexFolder then
		return
	end
	-- Top-level packages are alias ModuleScripts (direct children, not _Index)
	for _, child in packagesFolder:GetChildren() do
		if not child:IsA("ModuleScript") then
			continue
		end
		local packageId = extractPackageId(child.Source)
		if not packageId then
			continue
		end
		local scope, name, version = parsePackageId(packageId)
		if not scope or not name or not version then
			continue
		end
		local indexed = indexFolder:FindFirstChild(packageId)
		if not indexed then
			continue
		end
		table.insert(out, {
			scope = scope,
			name = name,
			version = version,
			realm = realm,
			packageId = packageId,
			indexFolder = indexed :: Folder,
			aliasLink = child :: ModuleScript,
		})
	end
end

function InstalledPackages.list(): { InstalledPackage }
	local out = {}
	scanRealm(ReplicatedStorage:FindFirstChild("Packages"), "shared", out)
	scanRealm(ServerStorage:FindFirstChild("ServerPackages"), "server", out)
	return out
end

function InstalledPackages.map(): { [string]: InstalledPackage }
	local out = {}
	for _, pkg in InstalledPackages.list() do
		out[`{pkg.scope}/{pkg.name}`] = pkg
	end
	return out
end

-- Returns the set of packageIds that `packageId` depends on (transitively),
-- by walking the alias ModuleScripts inside the package's indexed folder.
function InstalledPackages.collectDependencies(indexFolder: Folder, packageId: string): { [string]: true }
	local deps: { [string]: true } = {}
	local function walk(pkgId: string)
		local pkgFolder = indexFolder:FindFirstChild(pkgId)
		if not pkgFolder then
			return
		end
		for _, child in pkgFolder:GetChildren() do
			if not child:IsA("ModuleScript") then
				continue
			end
			local depId = extractPackageId(child.Source)
			if depId and depId ~= pkgId and not deps[depId] then
				deps[depId] = true
				walk(depId)
			end
		end
	end
	walk(packageId)
	return deps
end

return InstalledPackages
