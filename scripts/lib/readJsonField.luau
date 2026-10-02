--!strict

const json = require("@std/json")

--[[
	Reads `key` from a decoded JSON object. Returns nil when `value` is not a table or
		has no such key, so callers narrow the result with `typeof`.

	`typeof` cannot tell a JSON array from an object, so both are read as an object.
		Indexing an array by a string key returns nil, which is the right answer.
]]
const function readJsonField(value: json.Value, key: string): json.Value
	if typeof(value) ~= "table" then
		return nil
	end

	return (value :: json.Object)[key]
end

return readJsonField
