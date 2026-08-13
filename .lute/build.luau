--[[
	Builds the plugin to a .rbxm file. By default builds the release artifact;
	pass --dev to build a parallel dev artifact that can be installed alongside
	the release version without colliding on toolbar, widget, or plugin settings.

	Usage: lute run build [--dev|-d] [--output|-o <path>]
]]

local process = require("@lute/process")

local codegen = require("./lib/codegen")
local color = require("./lib/color")
local parseArgs = require("./lib/args")
local rojo = require("./lib/rojo")

local RELEASE_OUTPUT = "StudioDiscover.rbxm"
local DEV_OUTPUT = "StudioDiscover-Dev.rbxm"

local function run(dev: boolean, requestedOutput: string?)
	local output = requestedOutput or (if dev then DEV_OUTPUT else RELEASE_OUTPUT)

	local label = if dev then "dev" else "release"
	print(color.bold(color.white(`Building {label} plugin...\n`)))

	local codegenSuccess = codegen.run({
		quiet = false,
		dev = dev,
		generateSourcemap = true,
	})
	if not codegenSuccess then
		return
	end

	print()

	local buildResult = rojo.build({
		projectFile = "plugin/default.project.json",
		output = output,
		stdio = "inherit",
	})

	if not buildResult.ok then
		print(color.bold(color.red(`Rojo exited with code {buildResult.code} while building`)))
		if buildResult.stderr then
			print(buildResult.stderr)
		end
		process.exit(buildResult.code)
		return
	end

	print()
	print(color.bold(color.green(`Built {output}`)))
end

local args = parseArgs({ "output", "o" })
run(args.flags.dev or args.flags.d or false, args.values.output or args.values.o)
