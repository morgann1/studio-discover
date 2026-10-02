--!strict

export type UncheckedTable = { [unknown]: unknown }

--[[
	Narrows a decoded value, such as a JSON response or a lockfile, to a table whose
		keys and values are still unchecked, or returns nil when it is not a table.
]]
const function asTable(value: unknown): UncheckedTable?
	if typeof(value) == "table" then
		return value :: UncheckedTable
	end

	return nil
end

return asTable
