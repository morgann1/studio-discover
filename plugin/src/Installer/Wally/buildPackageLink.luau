--!strict

type Realm = "shared" | "server"

local function linkSameIndex(linkName: string, packageId: string, moduleName: string): ModuleScript
	local link = Instance.new("ModuleScript")
	link.Name = linkName
	link.Source = `return require(script.Parent.Parent["{packageId}"]["{moduleName}"])`
	return link
end

local function linkRootSameIndex(linkName: string, packageId: string, moduleName: string): ModuleScript
	local link = Instance.new("ModuleScript")
	link.Name = linkName
	link.Source = `return require(script.Parent._Index["{packageId}"]["{moduleName}"])`
	return link
end

local function linkSharedIndex(linkName: string, packageId: string, moduleName: string): ModuleScript
	local link = Instance.new("ModuleScript")
	link.Name = linkName
	link.Source = `return require(game.ReplicatedStorage.Packages._Index["{packageId}"]["{moduleName}"])`
	return link
end

local function linkServerIndex(linkName: string, packageId: string, moduleName: string): ModuleScript
	local link = Instance.new("ModuleScript")
	link.Name = linkName
	link.Source = `return require(game.ServerStorage.ServerPackages._Index["{packageId}"]["{moduleName}"])`
	return link
end

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
