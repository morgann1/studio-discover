--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Charm = require(StudioDiscover.Packages.Charm)

-- Mutex so concurrent installer operations can't race on `_Index` + lockfile.
local busyAtom = Charm.atom(false)

return busyAtom
