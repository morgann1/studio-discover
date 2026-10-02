--!strict

--[[
	Builds the test place and runs Jest inside Studio through run-in-roblox, which
		exits non-zero when the task errors. `--build-only` stops after the build.

	run-in-roblox needs a native Studio install and does not work under WSL. There,
		the build still runs, and the tests run from a Windows terminal or from
		Studio's command bar.

	Usage: lute scripts/test.luau [--build-only]
]]

const fs = require("@std/fs")
const process = require("@lute/process")

const color = require("@scripts/lib/color")
const parseArgs = require("@scripts/lib/parseArgs")
const project = require("@root/project")
const runAsync = require("@scripts/lib/runAsync")

const PLACE_DIRECTORY = "plugin/tests/build"
const PLACE_PATH = `{PLACE_DIRECTORY}/tests.rbxl`
const TASK_PATH = `{project.TASKS_PATH}/run-tests.luau`

const args = parseArgs()
const buildOnly = args.flags["build-only"] or args.flags.b or false
const isWsl = process.env.WSL_DISTRO_NAME ~= nil or process.env.WSL_INTEROP ~= nil

if not fs.exists(project.VENDORED_DEV_PACKAGES_PATH) then
	print(color.red("Packages are not installed. Run `lute scripts/install.luau` first."))
	process.exit(1)
end

fs.createDirectory(PLACE_DIRECTORY, { makeParents = true })
runAsync("rojo", { "build", project.TESTS_PROJECT_PATH, "--output", PLACE_PATH })

if buildOnly or isWsl then
	if isWsl then
		print(color.yellow("run-in-roblox does not work under WSL. Run this script from a Windows terminal instead."))
	end

	print(
		color.dim(`To run the tests by hand, open {PLACE_PATH} in Studio and paste {TASK_PATH} into the command bar.`)
	)
	process.exit(0)
end

runAsync("run-in-roblox", { "--place", PLACE_PATH, "--script", TASK_PATH })
