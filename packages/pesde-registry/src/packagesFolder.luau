--!strict

--[[
	The folders pesde packages live in: a realm's `PesdePackages` folder holds the
		roots' aliases, and the `.pesde` index inside it holds the packages.
]]

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const createPackagesFolders = require(StudioDiscover.Core.createPackagesFolders)

const packagesFolder = createPackagesFolders({
	shared = "PesdePackages",
	server = "PesdeServerPackages",
	index = ".pesde",
})

return packagesFolder
