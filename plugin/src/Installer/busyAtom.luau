--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Charm = require(StudioDiscover.Packages.Charm)

-- Whether an installer operation is running. Only `runWithBusyLock` writes it.
const busyAtom = Charm.atom(false)

return busyAtom
