--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Charm = require(StudioDiscover.Packages.Charm)

const types = require(script.Parent.types)

-- The navigation stack. The last screen is the one shown.
const screensAtom = Charm.atom({} :: { types.Screen })

return screensAtom
