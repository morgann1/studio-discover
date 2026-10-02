--!strict

--[[
	The link modules that make `Packages/Alias` resolve to the real content under
		`Packages/_Index`.

	This mirrors wally's link generation in `src/installation.rs`. Wally picks
		between four shapes based on the source and dependency realms; Discover needs
		three of them, because wally's fourth reaches into the server index from
		outside it and the only caller that can legitimately do that is a dev
		dependency, which Discover rejects outright.
]]

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const types = require(StudioDiscover.Core.types)

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

	A shared package cannot depend on a server one. `isDependencyValid` rejects
		that pairing during resolve, matching wally's `Realm::is_dependency_valid`,
		so reaching here with it means resolve is wrong. Writing the link anyway
		would put a `ServerStorage` require behind a module that replicates, which
		loads fine in Studio and then fails for every client at runtime. Failing the
		install is the better outcome: `applyRootsAsync` runs this inside a pcall and
		cancels the ChangeHistory recording, so the place is left untouched.
]]
const function buildSiblingPackageLink(
	linkName: string,
	packageId: string,
	moduleName: string,
	sourceRealm: types.Realm,
	dependencyRealm: types.Realm
): LinkBuild
	-- One package inside `_Index` requiring another beside it.
	if sourceRealm == dependencyRealm then
		return makeLink(linkName, `return require(script.Parent.Parent["{packageId}"]["{moduleName}"])`)
	end

	--[[
		A server package reaching across into the shared `_Index`. The path is the
			one the wally CLI writes, which `parseLink` reads back.
	]]
	if dependencyRealm == "shared" then
		return makeLink(
			linkName,
			`return require(game.ReplicatedStorage.Packages._Index["{packageId}"]["{moduleName}"])`
		)
	end

	error(`cannot link shared package to server dependency "{packageId}" as "{linkName}"`)
end

const buildPackageLink = table.freeze({
	buildRootPackageLink = buildRootPackageLink,
	buildSiblingPackageLink = buildSiblingPackageLink,
})

return buildPackageLink
