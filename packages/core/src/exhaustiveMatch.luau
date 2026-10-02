--!strict

--[[
	Closes a branch over a string literal union. Once every member has its own branch,
		the value left over is `never`, so adding a member without a branch is a type
		error at the call.
]]
const function exhaustiveMatch(value: never): never
	error(`unmatched case: {value}`)
end

return exhaustiveMatch
