--!strict

--[[
	Type checks with luau-lsp. The scripts run under Lute and are checked against
		the standard platform. The plugin, the packages, and the tasks that run inside
		Roblox are checked against the Roblox platform through the plugin's sourcemap.

	Usage: lute scripts/analyze.luau
]]

const process = require("@lute/process")

const codegenAsync = require("@scripts/lib/codegenAsync")
const downloadPinnedAsync = require("@scripts/lib/downloadPinnedAsync")
const project = require("@root/project")
const runAsync = require("@scripts/lib/runAsync")

const IGNORE_PATTERNS = table.freeze({
	`{project.VENDORED_PACKAGES_PATH}/**`,
	"**/.lute/typedefs/**",

	-- Specs resolve against the test place, not the plugin, so running them is what checks them.
	`{project.PACKAGES_PATH}/*/tests/**`,
})

-- Returns whether luau-lsp found nothing, so the second pass still runs after the first fails.
const function analyzeAsync(args: { string }): boolean
	const analyzeArgs = { "analyze" }

	for _, pattern in IGNORE_PATTERNS do
		table.insert(analyzeArgs, `--ignore={pattern}`)
	end

	table.move(args, 1, #args, #analyzeArgs + 1, analyzeArgs)

	const ok = pcall(function()
		runAsync("luau-lsp", analyzeArgs)
	end)

	return ok
end

downloadPinnedAsync(
	`https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/{project.LUAU_LSP_COMMIT}/scripts/globalTypes.d.luau`,
	project.GLOBAL_DEFS_PATH,
	project.LUAU_LSP_GLOBAL_TYPES_SHA256
)

codegenAsync({ sourcemap = true })

local failureCount = 0

-- Lute's typedefs are written for the new solver.
if
	not analyzeAsync({
		"--platform=standard",
		"--flag:LuauSolverV2=true",
		`--ignore={project.TASKS_PATH}/**`,
		project.PROJECT_MODULE_PATH,
		project.SCRIPTS_PATH,
	})
then
	failureCount += 1
end

-- Still on the old solver until the plugin is migrated, so this pass leaves out the editor
-- settings, which turn the new one on.
if
	not analyzeAsync({
		"--platform=roblox",
		`--sourcemap={project.SOURCEMAP_PATH}`,
		`--definitions={project.GLOBAL_DEFS_PATH}`,
		project.PACKAGES_PATH,
		project.PLUGIN_BIN_PATH,
		project.PLUGIN_SRC_PATH,
		project.TASKS_PATH,
	})
then
	failureCount += 1
end

process.exit(failureCount)
