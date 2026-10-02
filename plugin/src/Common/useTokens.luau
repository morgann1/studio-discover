--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Foundation = require(StudioDiscover.Packages.Foundation)

--[[
	Foundation's design tokens for the current theme. Foundation's `Hooks` table types
		as an error under the new solver, so this binding restores the hook's real type.
]]
const useTokens: () -> Foundation.Tokens = Foundation.Hooks.useTokens

return useTokens
