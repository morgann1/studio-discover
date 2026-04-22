--[[
	CI Command

	Runs static analysis checks: linting (Selene), formatting (StyLua),
	and type checking (luau-lsp).
]]

local fs = require("@lute/fs")
local net = require("@lute/net/client")
local process = require("@lute/process")

local codegen = require("./codegen")
local color = require("../utils/color")

local ci = {}

-- Metadata for help command
ci.name = "ci"
ci.description = "Runs static analysis (lint, format check, type check)"
ci.usage = "lute run ci [--fix]"

-- Argument definitions for CLI parsing
ci.arguments = {
	{
		name = "fix",
		kind = "flag",
		options = {
			help = "Auto-fix formatting issues instead of just checking",
			aliases = { "f" },
		},
	},
}

export type Options = {
	fix: boolean?,
}

-- Paths to analyze
local ANALYZE_PATHS = { ".lute", "plugin/bin", "plugin/src" }

-- Patterns to ignore in luau-lsp
local IGNORE_PATTERNS = { "plugin/Packages/**", "**/.lute/typedefs/**" }

local function isDir(path: string): boolean
	return fs.exists(path) and fs.type(path) == "dir"
end

local function isFile(path: string): boolean
	return fs.exists(path) and fs.type(path) == "file"
end

--[[
	Runs a command and returns whether it succeeded.

	@param program The program to run
	@param args The arguments to pass
	@param description A description for the step
	@return True if successful, false otherwise
]]
local function runStep(program: string, args: { string }, description: string): boolean
	print(color.cyan(`→ {description}`))

	local argv = { program }
	for _, arg in args do
		table.insert(argv, arg)
	end

	local result = process.run(argv, {
		stdio = "inherit",
	})

	if result.ok then
		print(color.green(`  ✓ {description} passed`))
		return true
	else
		print(color.red(`  ✗ {description} failed`))
		return false
	end
end

--[[
	Downloads the global Luau types file if it doesn't exist.

	@return True if successful, false otherwise
]]
local function fetchGlobalTypes(): boolean
	local typesFile = "plugin/generated/globalTypes.d.luau"

	if not isDir("plugin/generated") then
		fs.mkdir("plugin/generated")
	end

	if isFile(typesFile) then
		print(color.dim(`  Skipping download, {typesFile} already exists`))
		return true
	end

	print(color.cyan("→ Fetching Luau global types"))

	local response =
		net.request("https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/master/scripts/globalTypes.d.luau", {
			method = "GET",
		})

	if not response.ok then
		print(color.red(`  ✗ Failed to fetch global types: {response.status}`))
		return false
	end

	local handle = fs.open(typesFile, "w")
	fs.write(handle, response.body)
	fs.close(handle)
	print(color.green(`  ✓ Downloaded {typesFile}`))
	return true
end

--[[
	Runs all CI checks.

	@param options Configuration options
	@return True if all checks pass, false otherwise
]]
function ci.run(options_: Options?): boolean
	local options: Options = options_ or {}
	local fix = if options.fix ~= nil then options.fix else false

	print(color.bold(color.white("Running static analysis...\n")))

	local allPassed = true

	-- Step 1: Lint check (Selene)
	local seleneArgs = table.clone(ANALYZE_PATHS)
	if not runStep("selene", seleneArgs, "Lint check (Selene)") then
		allPassed = false
	end
	print()

	-- Step 2: Style check (StyLua)
	local styluaArgs = {}
	if not fix then
		table.insert(styluaArgs, "-c")
	end
	for _, path in ANALYZE_PATHS do
		table.insert(styluaArgs, path)
	end

	local styluaDesc = if fix then "Format (StyLua --fix)" else "Style check (StyLua)"
	if not runStep("stylua", styluaArgs, styluaDesc) then
		allPassed = false
	end
	print()

	-- Step 3: Fetch global types
	if not fetchGlobalTypes() then
		allPassed = false
	end
	print()

	-- Step 4: Update sourcemap
	print(color.cyan("→ Updating sourcemap"))
	local codegenSuccess = codegen.run({ quiet = true, generateSourcemap = true })
	if codegenSuccess then
		print(color.green("  ✓ Sourcemap updated"))
	else
		print(color.red("  ✗ Failed to update sourcemap"))
		allPassed = false
	end
	print()

	-- Step 5: Type check (luau-lsp)
	local luauArgs = {
		"analyze",
		"--sourcemap",
		"plugin/generated/sourcemap.json",
		"--platform",
		"roblox",
		"--definitions",
		"plugin/generated/globalTypes.d.luau",
		"--settings",
		".vscode/settings.json",
	}

	for _, pattern in IGNORE_PATTERNS do
		table.insert(luauArgs, `--ignore={pattern}`)
	end

	for _, path in ANALYZE_PATHS do
		table.insert(luauArgs, path)
	end

	if not runStep("luau-lsp", luauArgs, "Type check (luau-lsp)") then
		allPassed = false
	end
	print()

	-- Summary
	if allPassed then
		print(color.bold(color.green("All checks passed!")))
	else
		print(color.bold(color.red("Some checks failed.")))
		process.exit(1)
	end

	return allPassed
end

return ci
