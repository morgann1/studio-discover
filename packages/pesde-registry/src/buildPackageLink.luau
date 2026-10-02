--!strict

--[[
	The link modules that make `PesdePackages/Alias`, and each package's
		`roblox_packages/Alias`, resolve into the `.pesde` index through string
		requires.
]]

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const containerName = require(StudioDiscover.PesdeRegistry.containerName)
const libPathSegments = require(StudioDiscover.PesdeRegistry.libPathSegments)
const types = require(StudioDiscover.PesdeRegistry.types)

-- An unparented link and the source the caller writes through `setScriptSourceAsync`.
export type LinkBuild = {
	read link: ModuleScript,
	read source: string,
}

-- The path inside `.pesde` to a package's library module: its container, its version folder, then its root.
const function packagePath(dependency: types.PesdeResolvedPackage): string
	const segments = { containerName(dependency.scope, dependency.name), dependency.version, dependency.name }
	for _, segment in libPathSegments(dependency.libPath) do
		table.insert(segments, segment)
	end

	return table.concat(segments, "/")
end

const function makeLink(alias: string, path: string, typeExports: { string }?): LinkBuild
	const lines = { `local module = require("{path}")` }
	for _, line in typeExports or {} do
		table.insert(lines, line)
	end
	table.insert(lines, "return module")

	const link = Instance.new("ModuleScript")
	link.Name = alias

	return { link = link, source = table.concat(lines, "\n") }
end

-- The alias a root gets in its realm's `PesdePackages` folder, which sits beside `.pesde`.
const function buildTopLevelLink(
	alias: string,
	dependency: types.PesdeResolvedPackage,
	typeExports: { string }?
): LinkBuild
	return makeLink(alias, `./.pesde/{packagePath(dependency)}`, typeExports)
end

--[[
	The alias a package uses for one of its dependencies, from the `roblox_packages`
		folder in its root. That folder sits four levels below `.pesde`: container,
		version, root, then `roblox_packages` itself. Both packages are in the same
		realm, since resolve rejects a dependency on the other target.
]]
const function buildTransitiveLink(
	alias: string,
	dependency: types.PesdeResolvedPackage,
	typeExports: { string }?
): LinkBuild
	return makeLink(alias, `./{string.rep("../", 4)}{packagePath(dependency)}`, typeExports)
end

const buildPackageLink = table.freeze({
	buildTopLevelLink = buildTopLevelLink,
	buildTransitiveLink = buildTransitiveLink,
})

return buildPackageLink
