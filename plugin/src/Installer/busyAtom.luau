--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Charm = require(StudioDiscover.Packages.Charm)

-- `true` while any installer entry point is running its resolve+apply cycle.
-- Serves as a process-wide mutex so two concurrent install/uninstall/update
-- calls can't race on `_Index` mutations or the lockfile save.
local busyAtom = Charm.atom(false)

return busyAtom
