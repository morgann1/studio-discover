--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Charm = require(StudioDiscover.Packages.Charm)

local types = require(StudioDiscover.Core.types)

type InstalledRoot = types.InstalledRoot

local installedRootsAtom = Charm.atom(nil :: { InstalledRoot }?)

return installedRootsAtom
