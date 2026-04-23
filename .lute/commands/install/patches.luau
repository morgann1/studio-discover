--[[
	Wally Package Patching

	Discovers git-format patch files in plugin/patches/ and applies them
	to the corresponding packages in plugin/Packages/_Index/.
]]

local fs = require("@lute/fs")
local process = require("@lute/process")

local color = require("../../utils/color")

local PATCHES_DIR = "plugin/patches"
local PACKAGES_INDEX_DIR = "plugin/Packages/_Index"

local function isDir(path: string): boolean
	return fs.exists(path) and fs.type(path) == "dir"
end

--[[
	Applies all patches from plugin/patches/ to installed Wally packages.

	Patch filenames must match _Index directory names exactly:
	  plugin/patches/jsdotlua_jest-runtime@3.10.0.patch
	  → applies to plugin/Packages/_Index/jsdotlua_jest-runtime@3.10.0/

	@param quiet Whether to suppress output
	@return True if all patches applied successfully, false otherwise
]]
local function applyPatches(quiet: boolean?): boolean
	if not isDir(PATCHES_DIR) then
		return true
	end

	local patchFiles: { string } = {}
	for _, entry in fs.listdir(PATCHES_DIR) do
		if entry.name:match("%.patch$") then
			table.insert(patchFiles, entry.name)
		end
	end

	if #patchFiles == 0 then
		return true
	end

	table.sort(patchFiles)

	for _, patchFile in patchFiles do
		local targetDirName = patchFile:gsub("%.patch$", "")
		local targetPath = `{PACKAGES_INDEX_DIR}/{targetDirName}`

		if not isDir(targetPath) then
			if not quiet then
				print(color.yellow(`  Warning: Package directory not found for patch: {patchFile}`))
				print(color.yellow(`  Expected: {targetPath}`))
			end
			continue
		end

		if not quiet then
			print(color.dim(`  Applying {patchFile}`))
		end

		local patchFilePath = `{PATCHES_DIR}/{patchFile}`
		local result = process.run({
			"git",
			"apply",
			"--directory",
			targetPath,
			patchFilePath,
		})

		if not result.ok then
			if not quiet then
				print(color.red(`  Failed to apply patch: {patchFile}`))
				print(color.red(`  {result.stderr}`))
			end
			return false
		end
	end

	return true
end

return applyPatches
