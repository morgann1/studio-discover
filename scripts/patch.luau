--!strict

--[[
	Creates or updates a patch for a vendored package, in two runs:

		1. The first run snapshots the package's clean state in a throwaway git repo.
		2. Edit the package, then run again. The second run writes the diff to
			`plugin/patches/` and removes the throwaway repo.

	Install applies the patches after every package install.

	Usage: lute scripts/patch.luau <package-path>
		e.g. lute scripts/patch.luau plugin/Packages/_Index/jsdotlua_jest@3.10.0
]]

local fs = require("@std/fs")
local process = require("@lute/process")

local color = require("@scripts/lib/color")
local parseArgs = require("@scripts/lib/args")
local project = require("@root/project")
local run = require("@scripts/lib/run")

local function snapshot(packagePath: string)
	run("git", { "init", "--quiet" }, { cwd = packagePath })
	run("git", { "add", "-A" }, { cwd = packagePath })
	run("git", { "commit", "--quiet", "-m", "original" }, { cwd = packagePath })

	print(color.green("Snapshot taken. Edit the package, then run this again to write the patch."))
end

local function writePatch(packagePath: string, packageDir: string)
	run("git", { "add", "-A" }, { cwd = packagePath })

	local diff = process.run({ "git", "diff", "--cached" }, { cwd = packagePath })
	fs.removeDirectory(`{packagePath}/.git`, { recursive = true })

	if not diff.ok then
		error(`git diff failed: {diff.stderr}`, 0)
	end

	if string.match(diff.stdout, "%S") == nil then
		print(color.yellow("No changes detected. Nothing to patch."))
		return
	end

	local patchPath = `{project.PATCHES_PATH}/{packageDir}.patch`
	fs.createDirectory(project.PATCHES_PATH, { makeParents = true })
	fs.writeStringToFile(patchPath, diff.stdout)

	print(color.green(`Wrote {patchPath}. Run \`lute scripts/install.luau\` to check that it applies cleanly.`))
end

local args = parseArgs()
local packagePath = args.positionals[1]
if packagePath == nil then
	print(color.red("Usage: lute scripts/patch.luau <package-path>"))
	process.exit(1)
end

packagePath = string.gsub(packagePath, "/$", "")

if string.find(packagePath, "Packages/_Index/", 1, true) == nil or not fs.exists(packagePath) then
	print(color.red(`Not an installed package: {packagePath}. Expected a directory inside Packages/_Index/.`))
	process.exit(1)
end

local parts = string.split(packagePath, "/")
local packageDir = parts[#parts]

if fs.exists(`{packagePath}/.git`) then
	writePatch(packagePath, packageDir)
else
	snapshot(packagePath)
end
