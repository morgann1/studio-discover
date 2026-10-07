--!strict

--[[
	The attributes Discover marks each package in `node_modules` with. `PACKAGE_ID`
		holds the package id it installed, and `ROOT` marks a top-level package the user
		asked for. A folder without an id isn't Discover's, so it is left alone unless
		a package needs its name.
]]
const packageAttributes = table.freeze({
	PACKAGE_ID = "NevermorePackageId",
	ROOT = "NevermoreRoot",
})

return packageAttributes
