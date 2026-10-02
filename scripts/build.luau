--!strict

--[[
	Builds the plugin to a .rbxm. `--dev` builds a separate dev identity that
		installs alongside the release build without colliding on toolbar, widget,
		or plugin settings.

	Usage: lute scripts/build.luau [--dev] [--output <path>]
]]

const codegenAsync = require("@scripts/lib/codegenAsync")
const parseArgs = require("@scripts/lib/parseArgs")
const project = require("@root/project")
const runAsync = require("@scripts/lib/runAsync")

const args = parseArgs({ "output", "o" })
const dev = args.flags.dev or args.flags.d or false
const defaultOutput = if dev then "StudioDiscover-Dev.rbxm" else "StudioDiscover.rbxm"
const output = args.values.output or args.values.o or defaultOutput

codegenAsync({ dev = dev })
runAsync("rojo", { "build", project.PROJECT_PATH, "--output", output })
