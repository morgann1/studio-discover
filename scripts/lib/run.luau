--!strict

local process = require("@lute/process")

local color = require("@scripts/lib/color")

export type Options = {
	cwd: string?,
}

--[[
	Runs a program with its output streamed to the terminal, and errors when it exits
		non-zero. Arguments reach the program as-is, so paths need no shell quoting.

	Scripts that should keep going after a failed step wrap the call in `pcall`.
]]
local function run(program: string, params: { string }, options: Options?)
	print(color.bold(`> {program} {table.concat(params, " ")}`))

	local argv = table.clone(params)
	table.insert(argv, 1, program)

	local result = process.run(argv, {
		stdio = "inherit",
		cwd = if options ~= nil then options.cwd else nil,
	})

	if not result.ok then
		error(`{program} exited with code {result.exitcode}`, 0)
	end
end

return run
