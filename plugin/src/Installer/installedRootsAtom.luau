--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Charm = require(StudioDiscover.Packages.Charm)

local types = require(StudioDiscover.Source.Installer.types)

type InstalledRoot = types.InstalledRoot

-- `nil` is the "not yet seeded" marker — readers should populate it from
-- `snapshotRoots()` on first access. An empty table means "seeded, no roots."
local installedRootsAtom = Charm.atom(nil :: { InstalledRoot }?)

return installedRootsAtom
