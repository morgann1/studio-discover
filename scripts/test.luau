--!strict

--[[
	Builds the test place and runs Jest inside Studio through run-in-roblox, which
		exits non-zero when the task errors. `--build-only` stops after the build.

	run-in-roblox needs a native Studio install and does not work under WSL. There,
		the build still runs, and the tests run from a Windows terminal or from
		Studio's command bar.

	Usage: lute scripts/test.luau [--build-only]
]]

local fs = require("@std/fs")
local process = require("@lute/process")

local color = require("@scripts/lib/color")
local parseArgs = require("@scripts/lib/args")
local project = require("@root/project")
local run = require("@scripts/lib/run")

local PLACE_DIRECTORY = "plugin/tests/build"
local PLACE_PATH = `{PLACE_DIRECTORY}/tests.rbxl`
local TASK_PATH = "scripts/tasks/run-tests.luau"

local args = parseArgs()
local buildOnly = args.flags["build-only"] or args.flags.b or false
local isWsl = process.env.WSL_DISTRO_NAME ~= nil or process.env.WSL_INTEROP ~= nil

if not fs.exists(project.VENDORED_DEV_PACKAGES_PATH) then
	print(color.red("Packages are not installed. Run `lute scripts/install.luau` first."))
	process.exit(1)
end

fs.createDirectory(PLACE_DIRECTORY, { makeParents = true })
run("rojo", { "build", project.TESTS_PROJECT_PATH, "--output", PLACE_PATH })

if buildOnly or isWsl then
	if isWsl then
		print(color.yellow("run-in-roblox does not work under WSL. Run this script from a Windows terminal instead."))
	end

	print(
		color.dim(`To run the tests by hand, open {PLACE_PATH} in Studio and paste {TASK_PATH} into the command bar.`)
	)
	process.exit(0)
end

run("run-in-roblox", { "--place", PLACE_PATH, "--script", TASK_PATH })
