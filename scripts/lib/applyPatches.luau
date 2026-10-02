--!strict

local fs = require("@std/fs")

local color = require("@scripts/lib/color")
local project = require("@root/project")
local run = require("@scripts/lib/run")

--[[
	Applies every git-format patch in `plugin/patches/` to the installed package it
		names. A patch file is named for its `_Index` directory:

		plugin/patches/jsdotlua_jest-runtime@3.10.0.patch
		applies to plugin/Packages/_Index/jsdotlua_jest-runtime@3.10.0/

	A patch for a package that is no longer installed is skipped with a warning.
		One that no longer applies errors.
]]
local function applyPatches()
	if not fs.exists(project.PATCHES_PATH) then
		return
	end

	local patchFiles: { string } = {}
	for _, entry in fs.listDirectory(project.PATCHES_PATH) do
		if string.match(entry.name, "%.patch$") ~= nil then
			table.insert(patchFiles, entry.name)
		end
	end

	table.sort(patchFiles)

	for _, patchFile in patchFiles do
		local packageDir = string.gsub(patchFile, "%.patch$", "")
		local packagePath = `{project.VENDORED_PACKAGES_PATH}/_Index/{packageDir}`

		if not fs.exists(packagePath) then
			print(color.yellow(`Skipping {patchFile}: {packagePath} is not installed`))
			continue
		end

		run("git", { "apply", "--directory", packagePath, `{project.PATCHES_PATH}/{patchFile}` })
	end
end

return applyPatches
