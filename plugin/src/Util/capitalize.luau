--!strict

-- Uppercases the first character, as in "shared" to "Shared".
const function capitalize(value: string): string
	return string.upper(string.sub(value, 1, 1)) .. string.sub(value, 2)
end

return capitalize
