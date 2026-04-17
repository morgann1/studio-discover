local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Discover = script:FindFirstAncestor("Discover")

local formatPackageKey = require(Discover.Src.Util.formatPackageKey)

export type InstalledPackage = {
	scope: string,
	name: string,
	version: string,
	realm: "shared" | "server",
	packageId: string,
	indexFolder: Folder,
	aliasLink: ModuleScript,
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

local function extractPackageId(source: string): string?
	return source:match('%["([^"]+@[^"]+)"%]')
end

local function scanRealm(packagesFolder: Folder?, realm: "shared" | "server", out: { InstalledPackage })
	if not packagesFolder then
		return
	end
	local indexFolder = packagesFolder:FindFirstChild("_Index")
	if not indexFolder then
		return
	end
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

function InstalledPackages.extractPackageId(source: string): string?
	return extractPackageId(source)
end

function InstalledPackages.list(): { InstalledPackage }
	local out = {}
	scanRealm(ReplicatedStorage:FindFirstChild("Packages"), "shared", out)
	scanRealm(ServerStorage:FindFirstChild("ServerPackages"), "server", out)
	return out
end

function InstalledPackages.map(): { [string]: InstalledPackage }
	local out = {}
	for _, installedPackage in InstalledPackages.list() do
		out[formatPackageKey(installedPackage.scope, installedPackage.name)] = installedPackage
	end
	return out
end

function InstalledPackages.collectDependencies(indexFolder: Folder, packageId: string): { [string]: true }
	local deps: { [string]: true } = {}
	local function walk(walkPackageId: string)
		local packageFolder = indexFolder:FindFirstChild(walkPackageId)
		if not packageFolder then
			return
		end
		for _, child in packageFolder:GetChildren() do
			if not child:IsA("ModuleScript") then
				continue
			end
			local depId = extractPackageId(child.Source)
			if depId and depId ~= walkPackageId and not deps[depId] then
				deps[depId] = true
				walk(depId)
			end
		end
	end
	walk(packageId)
	return deps
end

function InstalledPackages.findDependents(scope: string, name: string): { InstalledPackage }
	local dependents = {}
	local targetPrefix = `{scope}_{name}@`
	for _, installedPackage in InstalledPackages.list() do
		if installedPackage.scope == scope and installedPackage.name == name then
			continue
		end
		local root = installedPackage.indexFolder.Parent :: Folder
		local deps = InstalledPackages.collectDependencies(root, installedPackage.packageId)
		for depId in deps do
			if string.sub(depId, 1, #targetPrefix) == targetPrefix then
				table.insert(dependents, installedPackage)
				break
			end
		end
	end
	return dependents
end

return InstalledPackages
