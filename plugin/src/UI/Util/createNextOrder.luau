--[[
	Returns a closure that yields an incrementing LayoutOrder value each call.
	Starts at 1. Use to keep sibling children ordered without hand-numbering.
]]
local function createNextOrder(): () -> number
	local order = 0
	return function()
		order += 1
		return order
	end
end

return createNextOrder
