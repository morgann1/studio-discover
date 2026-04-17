--!strict

local function createNextOrder(): () -> number
	local order = 0
	return function(): number
		order += 1
		return order
	end
end

return createNextOrder
