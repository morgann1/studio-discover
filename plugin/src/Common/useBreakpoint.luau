--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)

--[[
	Foundation's breakpoint for `instance`'s width, and that size. Foundation's `Hooks`
		table types as an error under the new solver, so this binding restores the
		hook's real type.
]]
const useBreakpoint: (instance: GuiBase2d?) -> (Foundation.Breakpoint, Vector2) = Foundation.Hooks.useBreakpoint

return useBreakpoint
