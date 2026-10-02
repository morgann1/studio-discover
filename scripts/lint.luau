--!strict

--[[
	Lints with Selene and checks formatting with StyLua. `--fix` formats in place
		instead of checking.

	Usage: lute scripts/lint.luau [--fix]
]]

local process = require("@lute/process")

local parseArgs = require("@scripts/lib/args")
local project = require("@root/project")
local run = require("@scripts/lib/run")

local PATHS_TO_LINT = {
	"project.luau",
	project.SCRIPTS_PATH,
	project.PACKAGES_PATH,
	"plugin/bin",
	"plugin/src",
}

local args = parseArgs()
local fix = args.flags.fix or args.flags.f or false

local styluaArgs = table.clone(PATHS_TO_LINT)
if not fix then
	table.insert(styluaArgs, 1, "--check")
end

-- Both run even when the first fails, so one pass reports everything.
local failureCount = 0

local seleneOk = pcall(function()
	run("selene", PATHS_TO_LINT)
end)

if not seleneOk then
	failureCount += 1
end

local styluaOk = pcall(function()
	run("stylua", styluaArgs)
end)

if not styluaOk then
	failureCount += 1
end

process.exit(failureCount)
