--[[
	Charm atom mirroring the set of installed packages. Refreshing reads
	from the Roblox DataModel via InstalledPackages — call `refresh()` after
	any install/uninstall so subscribers update.
]]

local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Charm = require(Packages.Charm)

local InstalledPackages = require(Discover.Src.Installer.InstalledPackages)

type InstalledPackage = InstalledPackages.InstalledPackage

local Installed = {}

Installed.list = Charm.atom({} :: { InstalledPackage })
Installed.map = Charm.atom({} :: { [string]: InstalledPackage })

function Installed.refresh()
	local list = InstalledPackages.list()
	local map: { [string]: InstalledPackage } = {}
	for _, pkg in list do
		map[`{pkg.scope}/{pkg.name}`] = pkg
	end
	Charm.batch(function()
		Installed.list(list)
		Installed.map(map)
	end)
end

-- Seed on first require so atoms are populated before any component reads them.
Installed.refresh()

return Installed
