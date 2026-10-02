--!strict

-- Narrows a decoded value to a string, or returns nil when it is anything else.
const function asString(value: unknown): string?
	return if typeof(value) == "string" then value else nil
end

return asString
