--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Charm = require(StudioDiscover.Packages.Charm)
const React = require(StudioDiscover.Packages.React)

--[[
	Returns the current value of a Charm selector, and re-renders the component
		whenever it changes. The subscription is made once on mount. Pass an atom
		through a selector, as in `useAtom(function() return busyAtom() end)`, since
		an atom's optional setter argument does not fit the selector type.
]]
const function useAtom<State>(selector: Charm.Selector<State>): State
	const state, setState = React.useState(selector())

	React.useEffect(function()
		setState(selector())

		return Charm.subscribe(selector, function(value)
			setState(value)
		end)
	end, {})

	return state
end

return useAtom
