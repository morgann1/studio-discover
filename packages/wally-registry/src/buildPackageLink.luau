--!strict

export type LinkBuild = {
	link: ModuleScript,
	source: string,
}

type Realm = "shared" | "server"

local function makeLink(linkName: string, source: string): LinkBuild
	local link = Instance.new("ModuleScript")
	link.Name = linkName
	return { link = link, source = source }
end

local function linkSameIndex(linkName: string, packageId: string, moduleName: string): LinkBuild
	return makeLink(linkName, `return require(script.Parent.Parent["{packageId}"]["{moduleName}"])`)
end

local function linkRootSameIndex(linkName: string, packageId: string, moduleName: string): LinkBuild
	return makeLink(linkName, `return require(script.Parent._Index["{packageId}"]["{moduleName}"])`)
end

local function linkSharedIndex(linkName: string, packageId: string, moduleName: string): LinkBuild
	return makeLink(linkName, `return require(game.ReplicatedStorage.Packages._Index["{packageId}"]["{moduleName}"])`)
end

local function linkServerIndex(linkName: string, packageId: string, moduleName: string): LinkBuild
	return makeLink(linkName, `return require(game.ServerStorage.ServerPackages._Index["{packageId}"]["{moduleName}"])`)
end

local function buildSiblingPackageLink(
	linkName: string,
	packageId: string,
	moduleName: string,
	sourceRealm: Realm,
	dependencyRealm: Realm
): LinkBuild
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
): LinkBuild
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
