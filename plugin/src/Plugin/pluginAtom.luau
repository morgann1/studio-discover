--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Charm = require(StudioDiscover.Packages.Charm)

-- The plugin handle, set once by `setupPlugin`. Plugin settings wait for it before they load.
const pluginAtom = Charm.atom(nil :: Plugin?)

return pluginAtom
