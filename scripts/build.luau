--!strict

--[[
	Builds the plugin to a .rbxm. `--dev` builds a separate dev identity that
		installs alongside the release build without colliding on toolbar, widget,
		or plugin settings.

	Usage: lute scripts/build.luau [--dev] [--output <path>]
]]

local codegen = require("@scripts/lib/codegen")
local parseArgs = require("@scripts/lib/args")
local project = require("@root/project")
local run = require("@scripts/lib/run")

local args = parseArgs({ "output", "o" })
local dev = args.flags.dev or args.flags.d or false
local output = args.values.output or args.values.o or (if dev then "StudioDiscover-Dev.rbxm" else "StudioDiscover.rbxm")

codegen({ dev = dev })
run("rojo", { "build", project.PROJECT_PATH, "--output", output })
