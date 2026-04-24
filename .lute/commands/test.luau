--[[
	Test Command

	Builds a test place from plugin/tests/test.project.json and runs Jest
	inside it via run-in-roblox. Falls back to a build-only mode with
	instructions when run-in-roblox is not installed or --build-only is set.
]]

local fs = require("@lute/fs")
local process = require("@lute/process")

local color = require("../utils/color")

local test = {}

test.name = "test"
test.description = "Runs Jest tests via run-in-roblox"
test.usage = "lute run test [--build-only]"

test.arguments = {
	{
		name = "build-only",
		kind = "flag",
		options = {
			help = "Only build the test place; skip running it",
			aliases = { "b" },
		},
	},
}

export type Options = {
	buildOnly: boolean?,
}

local PROJECT = "plugin/test.project.json"
local OUTPUT = "plugin/tests/build/tests.rbxl"
local RUNNER_SCRIPT = "plugin/tests/runTests.server.luau"

local function isFile(path: string): boolean
	return fs.exists(path) and fs.type(path) == "file"
end

local function hasProgram(program: string): boolean
	local result = process.run({ program, "--version" }, { stdio = "default" })
	return result.ok
end

function test.run(options_: Options?): ()
	local options: Options = options_ or {}
	local buildOnly = options.buildOnly == true

	if not isFile(PROJECT) then
		print(color.red(`  ✗ Test project not found at {PROJECT}`))
		process.exit(1)
		return
	end

	if not fs.exists("plugin/tests/build") then
		fs.mkdir("plugin/tests/build")
	end

	print(color.cyan(`→ Building test place`))
	local build = process.run({ "rojo", "build", PROJECT, "-o", OUTPUT }, { stdio = "inherit" })
	if not build.ok then
		print(color.red(`  ✗ rojo build failed`))
		process.exit(1)
		return
	end
	print(color.green(`  ✓ {OUTPUT}`))

	if buildOnly then
		print()
		print(color.dim(`  Open {OUTPUT} in Studio and run {RUNNER_SCRIPT} from the command bar.`))
		return
	end

	if not hasProgram("run-in-roblox") then
		print()
		print(color.yellow(`  run-in-roblox not found on PATH.`))
		print(color.dim(`  Install via rokit or run manually:`))
		print(color.dim(`    open {OUTPUT} in Studio and run {RUNNER_SCRIPT} from the command bar.`))
		return
	end

	print()
	print(color.cyan(`→ Running tests`))
	local run = process.run({
		"run-in-roblox",
		"--place",
		OUTPUT,
		"--script",
		RUNNER_SCRIPT,
	}, { stdio = "inherit" })

	if not run.ok then
		print(color.red(`  ✗ Tests failed`))
		process.exit(1)
		return
	end
	print(color.green(`  ✓ Tests passed`))
end

return test
