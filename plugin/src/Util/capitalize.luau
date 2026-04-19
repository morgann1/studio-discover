--!strict

local function capitalize(value: string): string
	if value == "" then
		return value
	end
	return string.upper(string.sub(value, 1, 1)) .. string.sub(value, 2)
end

return capitalize
