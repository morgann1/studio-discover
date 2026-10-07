--!strict

-- Splits a scoped npm name, such as "@quenty/maid", into its scope and name. Returns nils for any other name.
const function splitNpmName(fullName: string): (string?, string?)
	const scope, name = fullName:match("^@([^/]+)/([^/]+)$")
	return scope, name
end

return splitNpmName
