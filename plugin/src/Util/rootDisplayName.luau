--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const coreTypes = require(StudioDiscover.Libraries.Core.types)
const packageDisplayName = require(StudioDiscover.Source.Util.packageDisplayName)

--[[
	The name an installed root goes by in the UI. A Wally or pesde root goes by its
		alias, the ModuleScript code requires. A Nevermore root's alias is only its
		npm folder, so it goes by the name its package page shows.
]]
const function rootDisplayName(root: coreTypes.InstalledRoot, settings: packageDisplayName.NameSettings): string
	if root.registry == "nevermore" then
		return packageDisplayName(root.registry, root.name, settings)
	end

	return root.alias
end

return rootDisplayName
