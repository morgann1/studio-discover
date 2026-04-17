local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Charm = require(Packages.Charm)

local InstalledPackages = require(Discover.Src.WallyInstall.InstalledPackages)
local formatPackageKey = require(Discover.Src.Util.formatPackageKey)

type InstalledPackage = InstalledPackages.InstalledPackage

local Installed = {}

Installed.list = Charm.atom({} :: { InstalledPackage })
Installed.map = Charm.atom({} :: { [string]: InstalledPackage })

function Installed.refresh()
	local list = InstalledPackages.list()
	local map: { [string]: InstalledPackage } = {}
	for _, installedPackage in list do
		map[formatPackageKey(installedPackage.scope, installedPackage.name)] = installedPackage
	end
	Charm.batch(function()
		Installed.list(list)
		Installed.map(map)
	end)
end

Installed.refresh()

return Installed
