--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Charm = require(StudioDiscover.Packages.Charm)

local types = require(StudioDiscover.Source.Installer.types)

type InstalledRoot = types.InstalledRoot

-- `nil` = not seeded yet; `{}` = seeded with no roots.
local installedRootsAtom = Charm.atom(nil :: { InstalledRoot }?)

return installedRootsAtom
