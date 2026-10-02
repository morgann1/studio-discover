--!strict

--[[
	Returns `alias`, or the first of `alias2`, `alias3`, and so on that `isTaken`
		accepts, so a new root never takes the name of another root in its realm.
]]
const function pickFreeAlias(alias: string, isTaken: (candidate: string) -> boolean): string
	local candidate = alias
	local suffix = 2

	while isTaken(candidate) do
		candidate = `{alias}{suffix}`
		suffix += 1
	end

	return candidate
end

return pickFreeAlias
