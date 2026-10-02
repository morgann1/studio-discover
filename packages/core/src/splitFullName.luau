--!strict

-- Splits "scope/name" at its last slash. Returns nils when either half would be empty.
const function splitFullName(fullName: string): (string?, string?)
	const scope, name = fullName:match("^(.+)/(.+)$")
	return scope, name
end

return splitFullName
