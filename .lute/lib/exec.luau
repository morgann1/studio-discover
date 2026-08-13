--[[
	Enhanced Process Execution

	Provides a consistent interface for executing external processes with
	better error handling, quiet/verbose modes, and output management.
]]

local process = require("@lute/process")

type Options = {
	cwd: string?,
	env: { [string]: string }?,
	quiet: boolean?,
}

--[[
	Executes a program with the given parameters.

	@param program The program to execute
	@param params The parameters to pass to the program
	@param options Optional execution options
	@return The stdout output (trimmed of trailing newline)
	@error Throws an error if the process exits with a non-zero code
]]
local function run(program: string, params: { string }, options: Options?): string
	local quiet = if options and options.quiet ~= nil then options.quiet else false

	if not quiet then
		print(`RUN > {program} {table.concat(params, " ")}`)
	end

	local argv = { program }
	for _, param in params do
		table.insert(argv, param)
	end

	local result = process.run(argv, {
		stdio = if quiet then "default" else "inherit",
		cwd = if options then options.cwd else nil,
		env = if options then options.env else nil,
	})

	if result.ok then
		return (result.stdout:gsub("\n$", ""))
	else
		error(result.stderr)
	end
end

return {
	run = run,
}
