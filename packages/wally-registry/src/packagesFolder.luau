--!strict

--[[
	The folders a realm's roots and `_Index` live in. They are the folders the wally
		CLI writes, so a place can mix the two.
]]

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const createPackagesFolders = require(StudioDiscover.Libraries.Core.createPackagesFolders)

const packagesFolder = createPackagesFolders({
	shared = "Packages",
	server = "ServerPackages",
	index = "_Index",
})

return packagesFolder
