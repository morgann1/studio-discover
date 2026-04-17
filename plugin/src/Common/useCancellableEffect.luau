--!strict

local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)

local function useCancellableEffect(setup: (isCancelled: () -> boolean) -> (), deps: { any })
	React.useEffect(function()
		local cancelled = false
		setup(function(): boolean
			return cancelled
		end)
		return function()
			cancelled = true
		end
	end, deps)
end

return useCancellableEffect
