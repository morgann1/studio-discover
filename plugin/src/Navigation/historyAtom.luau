--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Charm = require(StudioDiscover.Packages.Charm)

const createScreen = require(script.Parent.createScreen)
const types = require(script.Parent.types)

const INITIAL: types.History = {
	stack = { createScreen({ name = "Installed" }) },
	forward = {},
}

-- The navigation history. The last screen on the stack is the one shown.
const historyAtom = Charm.atom(INITIAL)

return historyAtom
