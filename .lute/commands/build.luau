--[[
	Build Command

	Builds the plugin to a .rbxm file. By default builds the release
	artifact; pass --dev to build a parallel dev artifact that can be
	installed alongside the release version without colliding on toolbar,
	widget, or plugin settings.
]]

local codegen = require("./codegen")
local color = require("../utils/color")
local errors = require("../lib/cli/errors")
local rojo = require("../lib/project/rojo")

local build = {}

-- Metadata for help command
build.name = "build"
build.description = "Builds the plugin to a .rbxm (release by default, --dev for a dev build)"
build.usage = "lute run build [--dev] [--output <path>]"

-- Argument definitions for CLI parsing
build.arguments = {
	{
		name = "output",
		kind = "option",
		options = {
			help = "Output file path (default: StudioDiscover.rbxm or StudioDiscover-Dev.rbxm)",
			aliases = { "o" },
		},
	},
	{
		name = "dev",
		kind = "flag",
		options = {
			help = "Build a dev variant with differentiated identity (separate toolbar, widget, settings)",
			aliases = { "d" },
		},
	},
}

export type Options = {
	output: string?,
	dev: boolean?,
}

local RELEASE_OUTPUT = "StudioDiscover.rbxm"
local DEV_OUTPUT = "StudioDiscover-Dev.rbxm"

--[[
	Builds the plugin.

	@param options Configuration options
]]
function build.run(options_: Options?)
	local options: Options = options_ or {}
	local dev = options.dev == true
	local output = options.output or (if dev then DEV_OUTPUT else RELEASE_OUTPUT)

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
		errors.processError(
			`Rojo exited with code {buildResult.code} while building`,
			buildResult.code,
			buildResult.stderr
		)
		return
	end

	print()
	print(color.bold(color.green(`Built {output}`)))
end

return build
