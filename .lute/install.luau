--[[
	Installs Wally packages, pulls the Roblox-only packages, and applies patches.

	Usage: lute run install [--quiet]

	The work lives in lib/install because setup and test both run it first.
]]

local process = require("@lute/process")

local install = require("./lib/install")
local parseArgs = require("./lib/args")

local args = parseArgs()

local ok = install.run({
	quiet = args.flags.quiet or args.flags.q,
})

if not ok then
	process.exit(1)
end
