--!strict

type Realm = "shared" | "server"

-- Links inside the same _Index (sibling package), relative require walking
-- up two levels: `script.Parent.Parent["{packageId}"]["{moduleName}"]`.
local function linkSameIndex(linkName: string, packageId: string, moduleName: string): ModuleScript
	local link = Instance.new("ModuleScript")
	link.Name = linkName
	link.Source = `return require(script.Parent.Parent["{packageId}"]["{moduleName}"])`
	return link
end

-- Links at the root of a Packages/ folder (top-level alias) pointing into
-- the `_Index` sibling.
local function linkRootSameIndex(linkName: string, packageId: string, moduleName: string): ModuleScript
	local link = Instance.new("ModuleScript")
	link.Name = linkName
	link.Source = `return require(script.Parent._Index["{packageId}"]["{moduleName}"])`
	return link
end

-- Cross-realm link into shared Packages (absolute path).
local function linkSharedIndex(linkName: string, packageId: string, moduleName: string): ModuleScript
	local link = Instance.new("ModuleScript")
	link.Name = linkName
	link.Source = `return require(game.ReplicatedStorage.Packages._Index["{packageId}"]["{moduleName}"])`
	return link
end

-- Cross-realm link into ServerPackages (absolute path).
local function linkServerIndex(linkName: string, packageId: string, moduleName: string): ModuleScript
	local link = Instance.new("ModuleScript")
	link.Name = linkName
	link.Source = `return require(game.ServerStorage.ServerPackages._Index["{packageId}"]["{moduleName}"])`
	return link
end

-- Link for a dep-to-dep reference inside _Index.
local function buildSiblingPackageLink(
	linkName: string,
	packageId: string,
	moduleName: string,
	sourceRealm: Realm,
	dependencyRealm: Realm
): ModuleScript
	if sourceRealm == dependencyRealm then
		return linkSameIndex(linkName, packageId, moduleName)
	end
	if dependencyRealm == "shared" then
		return linkSharedIndex(linkName, packageId, moduleName)
	end
	return linkServerIndex(linkName, packageId, moduleName)
end

-- Link at the root of a realm's packages folder (top-level alias).
local function buildRootPackageLink(
	linkName: string,
	packageId: string,
	moduleName: string,
	sourceRealm: Realm,
	dependencyRealm: Realm
): ModuleScript
	if sourceRealm == dependencyRealm then
		return linkRootSameIndex(linkName, packageId, moduleName)
	end
	if dependencyRealm == "shared" then
		return linkSharedIndex(linkName, packageId, moduleName)
	end
	return linkServerIndex(linkName, packageId, moduleName)
end

return {
	buildSiblingPackageLink = buildSiblingPackageLink,
	buildRootPackageLink = buildRootPackageLink,
}
