--!strict

--[[
	Returns a counter for `LayoutOrder`. Create one at the top of a render and call it
		for each child, so inserting a child never renumbers the rest.
]]
const function createNextOrder(): () -> number
	local layoutOrder = 0

	return function()
		layoutOrder += 1
		return layoutOrder
	end
end

return createNextOrder
