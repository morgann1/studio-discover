--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Charm = require(StudioDiscover.Packages.Charm)

const types = require(StudioDiscover.Libraries.Core.types)

-- The roots installed in the place, or nil until `refreshInstalledRoots` first reads them.
const installedRootsAtom = Charm.atom<<{ types.InstalledRoot }?>>(nil)

return installedRootsAtom
