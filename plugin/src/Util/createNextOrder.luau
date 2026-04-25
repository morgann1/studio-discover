--!strict

local function createNextOrder(): () -> number
	local n = 0
	return function()
		n += 1
		return n
	end
end

return createNextOrder
