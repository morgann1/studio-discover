--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Charm = require(StudioDiscover.Packages.Charm)
local React = require(StudioDiscover.Packages.React)

--[[
	Returns the current value of a Charm atom or selector, and re-renders the
		component whenever it changes. The subscription is made once on mount.
]]
local function useAtom<State>(selector: Charm.Selector<State>): State
	local state, setState = React.useState(selector)

	React.useEffect(function()
		setState(selector())
		return Charm.subscribe(selector, setState)
	end, {})

	return state
end

return useAtom
