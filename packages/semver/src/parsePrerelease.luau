--!strict

export type PrereleaseIdent = number | string

-- Splits a prerelease like `rc.2` into its identifiers, numbering the numeric ones.
const function parsePrerelease(raw: string): { PrereleaseIdent }
	const idents: { PrereleaseIdent } = {}
	for part in raw:gmatch("[^%.]+") do
		const number = if part:match("^%d+$") ~= nil then tonumber(part) else nil
		table.insert(idents, if number ~= nil then number else part)
	end

	return idents
end

return parsePrerelease
