--!strict

--[[
	Creates or updates a patch for a vendored package, in two runs:

		1. The first run snapshots the package's clean state in a throwaway git repo.
		2. Edit the package, then run again. The second run writes the diff to
			`plugin/patches/` and removes the throwaway repo.

	Install applies the patches after every package install.

	Usage: lute scripts/patch.luau <package-path>
		e.g. lute scripts/patch.luau plugin/Packages/_Index/roblox_react-shared@17.3.12
]]

const fs = require("@std/fs")
const process = require("@lute/process")

const color = require("@scripts/lib/color")
const parseArgs = require("@scripts/lib/parseArgs")
const project = require("@root/project")
const runAsync = require("@scripts/lib/runAsync")

const function snapshotAsync(packagePath: string): ()
	runAsync("git", { "init", "--quiet" }, { cwd = packagePath })
	runAsync("git", { "add", "-A" }, { cwd = packagePath })
	runAsync("git", { "commit", "--quiet", "-m", "original" }, { cwd = packagePath })

	print(color.green("Snapshot taken. Edit the package, then run this again to write the patch."))
end

const function writePatchAsync(packagePath: string, packageDir: string): ()
	runAsync("git", { "add", "-A" }, { cwd = packagePath })

	const diff = process.run({ "git", "diff", "--cached" }, { cwd = packagePath })
	fs.removeDirectory(`{packagePath}/.git`, { recursive = true })

	if not diff.ok then
		error(`git diff failed: {diff.stderr}`, 0)
	end

	if string.match(diff.stdout, "%S") == nil then
		print(color.yellow("No changes detected. Nothing to patch."))
		return
	end

	const patchPath = `{project.PATCHES_PATH}/{packageDir}.patch`
	fs.createDirectory(project.PATCHES_PATH, { makeParents = true })
	fs.writeStringToFile(patchPath, diff.stdout)

	print(color.green(`Wrote {patchPath}. Run \`lute scripts/install.luau\` to check that it applies cleanly.`))
end

const args = parseArgs()
const rawPackagePath = args.positionals[1]
if rawPackagePath == nil then
	print(color.red("Usage: lute scripts/patch.luau <package-path>"))
	process.exit(1)
end

const packagePath = string.gsub(rawPackagePath, "/$", "")

if string.find(packagePath, "Packages/_Index/", 1, true) == nil or not fs.exists(packagePath) then
	print(color.red(`Not an installed package: {packagePath}. Expected a directory inside Packages/_Index/.`))
	process.exit(1)
end

const parts = string.split(packagePath, "/")
const packageDir = parts[#parts]

if fs.exists(`{packagePath}/.git`) then
	writePatchAsync(packagePath, packageDir)
else
	snapshotAsync(packagePath)
end
