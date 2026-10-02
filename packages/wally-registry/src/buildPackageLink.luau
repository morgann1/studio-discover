--!strict

--[[
	The link modules that make `Packages/Alias` resolve to the real content under
		`Packages/_Index`.

	This mirrors wally's link generation in `src/installation.rs`, which picks one
		of four shapes from the source and dependency realms. Discover writes the
		same shapes.
]]

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const packagesFolder = require(StudioDiscover.Libraries.WallyRegistry.packagesFolder)
const types = require(StudioDiscover.Libraries.Core.types)

-- An unparented link and the source the caller writes through `setScriptSourceAsync`.
export type LinkBuild = {
	read link: ModuleScript,
	read source: string,
}

const function makeLink(linkName: string, source: string): LinkBuild
	const link = Instance.new("ModuleScript")
	link.Name = linkName

	return { link = link, source = source }
end

--[[
	The alias a root gets in `Packages`, pointing down into its own `_Index`.

	Roots are written into the `Packages` folder of their own realm, so a root link
		never crosses realms and takes no realm arguments.
]]
const function buildRootPackageLink(linkName: string, packageId: string, moduleName: string): LinkBuild
	return makeLink(linkName, `return require(script.Parent._Index["{packageId}"]["{moduleName}"])`)
end

--[[
	The link one package uses to require a dependency.

	Within one realm the link requires the package beside it in `_Index`. Across
		realms it requires out of the other realm's `_Index` by its full path, as
		wally's `link_shared_index` and `link_server_index` do. `parseLink` reads both
		shapes back.

	A shared package depends on a server one when resolve promotes it to shared
		after its server dependencies were placed, which wally does too. The link then
		puts a `ServerStorage` require inside a module that replicates, so a client
		that requires it fails. The package declared `realm = "server"`, so clients
		should not require it, and wally's output behaves the same way.
]]
const function buildSiblingPackageLink(
	linkName: string,
	packageId: string,
	moduleName: string,
	sourceRealm: types.Realm,
	dependencyRealm: types.Realm
): LinkBuild
	if sourceRealm == dependencyRealm then
		return makeLink(linkName, `return require(script.Parent.Parent["{packageId}"]["{moduleName}"])`)
	end

	return makeLink(
		linkName,
		`return require(game.{packagesFolder.path(dependencyRealm)}._Index["{packageId}"]["{moduleName}"])`
	)
end

const buildPackageLink = table.freeze({
	buildRootPackageLink = buildRootPackageLink,
	buildSiblingPackageLink = buildSiblingPackageLink,
})

return buildPackageLink
