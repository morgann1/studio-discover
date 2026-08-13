--[[
	Runs all code generation and refreshes the sourcemap.

	Usage: lute run codegen [--quiet]

	The work lives in lib/codegen because ci, build, install and setup all run it
	as a step rather than shelling out to this command.
]]

local process = require("@lute/process")

local codegen = require("./lib/codegen")
local parseArgs = require("./lib/args")

local args = parseArgs()

local ok = codegen.run({
	quiet = args.flags.quiet or args.flags.q,
	generateSourcemap = true,
})

if not ok then
	process.exit(1)
end
