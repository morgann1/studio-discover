--[[
	Setup Command

	Sets up the project for development or CI. Runs code generation and installs packages.
]]

local fs = require("@lute/fs")
local process = require("@lute/process")

local codegen = require("./lib/codegen")
local color = require("./lib/color")
local install = require("./lib/install")
local parseArgs = require("./lib/args")

local function isDir(path: string): boolean
	return fs.exists(path) and fs.type(path) == "dir"
end

--[[
	Sets up the project by running codegen and installing packages.

	@param options Configuration options
	@return True if successful, false otherwise
]]
local function run(quiet: boolean): boolean
	if not quiet then
		print(color.bold(color.white("Setting up project...\n")))
	end

	if not isDir("plugin/generated") then
		fs.mkdir("plugin/generated")
	end

	-- Run code generation
	local codegenSuccess = codegen.run({
		quiet = quiet,
		-- Generating the sourcemap requires packages to be installed, but we
		-- can't install packages before this step because it requires the
		-- sourcemap project to be generated. So we generate most of the code
		-- now, and generate the sourcemap later.
		generateSourcemap = false,
	})
	if not codegenSuccess then
		return false
	end

	if not quiet then
		print()
	end

	-- Install packages
	local installSuccess = install.run({ quiet = quiet })
	if not installSuccess then
		return false
	end

	-- Generate sourcemap
	codegenSuccess = codegen.run({
		quiet = quiet,
		generateSourcemap = true,
	})
	if not codegenSuccess then
		return false
	end

	if not quiet then
		print()
		print(color.bold(color.green("Project setup complete!")))
	end

	return true
end

local args = parseArgs()
if not run(args.flags.quiet or args.flags.q or false) then
	process.exit(1)
end
