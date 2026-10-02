--!strict

--[[
	Type checks with luau-lsp. The scripts run under Lute and are checked against
		the standard platform. The plugin, the packages, and the tasks that run inside
		Roblox are checked against the Roblox platform through the plugin's sourcemap.

	Usage: lute scripts/analyze.luau
]]

local process = require("@lute/process")

local codegen = require("@scripts/lib/codegen")
local downloadPinned = require("@scripts/lib/downloadPinned")
local project = require("@root/project")
local run = require("@scripts/lib/run")

-- Specs resolve against the test place, not the plugin, so running them is what checks them.
local IGNORE_PATTERNS = {
	"plugin/Packages/**",
	"**/.lute/typedefs/**",
	"packages/*/tests/**",
}

-- Returns whether luau-lsp found nothing, so the second pass still runs after the first fails.
local function analyze(args: { string }): boolean
	local analyzeArgs = { "analyze" }

	for _, pattern in IGNORE_PATTERNS do
		table.insert(analyzeArgs, `--ignore={pattern}`)
	end

	for _, arg in args do
		table.insert(analyzeArgs, arg)
	end

	local ok = pcall(function()
		run("luau-lsp", analyzeArgs)
	end)

	return ok
end

downloadPinned(
	`https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/{project.LUAU_LSP_COMMIT}/scripts/globalTypes.d.luau`,
	project.GLOBAL_DEFS_PATH,
	project.LUAU_LSP_GLOBAL_TYPES_SHA256
)

codegen({ sourcemap = true })

local failureCount = 0

-- Lute's typedefs are written for the new solver.
if
	not analyze({
		"--platform=standard",
		"--flag:LuauSolverV2=true",
		"--ignore=scripts/tasks/**",
		"project.luau",
		project.SCRIPTS_PATH,
	})
then
	failureCount += 1
end

if
	not analyze({
		"--platform=roblox",
		`--sourcemap={project.SOURCEMAP_PATH}`,
		`--definitions={project.GLOBAL_DEFS_PATH}`,
		"--settings=.vscode/settings.json",
		project.PACKAGES_PATH,
		"plugin/bin",
		"plugin/src",
		"scripts/tasks",
	})
then
	failureCount += 1
end

process.exit(failureCount)
