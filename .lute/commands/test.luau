--[[
	Test Command

	Builds a test place from plugin/tests/test.project.json and runs Jest
	inside it via run-in-roblox. Falls back to a build-only mode with
	instructions when run-in-roblox is not installed or --build-only is set.
]]

local fs = require("@lute/fs")
local process = require("@lute/process")

local color = require("../utils/color")
local install = require("./install")

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

local function isDir(path: string): boolean
	return fs.exists(path) and fs.type(path) == "dir"
end

local function rokitDeclares(tool: string): boolean
	if not isFile("rokit.toml") then
		return false
	end
	local handle = fs.open("rokit.toml", "r")
	local contents = fs.read(handle)
	fs.close(handle)
	for line in contents:gmatch("[^\r\n]+") do
		local name = line:match("^%s*([%w%-_]+)%s*=")
		if name == tool then
			return true
		end
	end
	return false
end

function test.run(options_: Options?): ()
	local options: Options = options_ or {}
	local buildOnly = options.buildOnly == true

	if not isFile(PROJECT) then
		print(color.red(`  ✗ Test project not found at {PROJECT}`))
		process.exit(1)
		return
	end

	if not isDir("plugin/Packages") or not isDir("plugin/DevPackages") then
		local ok = install.run({ quiet = true })
		if not ok then
			process.exit(1)
			return
		end
		print()
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

	if not rokitDeclares("run-in-roblox") then
		print()
		print(color.yellow(`  run-in-roblox is not declared in rokit.toml.`))
		print(color.dim(`  Add it with 'rokit add rojo-rbx/run-in-roblox', or run manually:`))
		print(color.dim(`    open {OUTPUT} in Studio and run {RUNNER_SCRIPT} from the command bar.`))
		return
	end

	print()
	print(color.cyan(`→ Running tests`))
	local ranOk, runResult = pcall(process.run, {
		"run-in-roblox",
		"--place",
		OUTPUT,
		"--script",
		RUNNER_SCRIPT,
	}, { stdio = "inherit" })

	if not ranOk then
		print(color.red(`  ✗ Could not invoke run-in-roblox: {runResult}`))
		print(color.dim(`  Run 'rokit install' and try again, or open {OUTPUT} in Studio manually.`))
		process.exit(1)
		return
	end
	if not runResult.ok then
		print(color.red(`  ✗ Tests failed`))
		process.exit(1)
		return
	end
	print(color.green(`  ✓ Tests passed`))
end

return test
