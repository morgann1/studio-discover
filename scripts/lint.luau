--!strict

--[[
	Lints with Selene and checks formatting with StyLua. `--fix` formats in place
		instead of checking.

	Usage: lute scripts/lint.luau [--fix]
]]

const process = require("@lute/process")

const parseArgs = require("@scripts/lib/parseArgs")
const project = require("@root/project")
const runAsync = require("@scripts/lib/runAsync")

const PATHS_TO_LINT = table.freeze({
	project.PROJECT_MODULE_PATH,
	project.SCRIPTS_PATH,
	project.PACKAGES_PATH,
	project.PLUGIN_BIN_PATH,
	project.PLUGIN_SRC_PATH,
	project.PLUGIN_TESTS_PATH,
})

const args = parseArgs()
const fix = args.flags.fix or args.flags.f or false

const styluaArgs = table.clone(PATHS_TO_LINT)
if not fix then
	table.insert(styluaArgs, 1, "--check")
end

-- Both run even when the first fails, so one pass reports everything.
local failureCount = 0

const seleneOk = pcall(function()
	runAsync("selene", PATHS_TO_LINT)
end)

if not seleneOk then
	failureCount += 1
end

const styluaOk = pcall(function()
	runAsync("stylua", styluaArgs)
end)

if not styluaOk then
	failureCount += 1
end

process.exit(failureCount)
