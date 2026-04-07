--[[
	Foundation Package Installation

	Installs Foundation packages from an upstream packages directory.
	Patches React references to point to the Wally-installed React package.
]]

local fs = require("@lune/fs")

local TEMP_DIR = "tmp"

local function withTempDir(callback: (path: string) -> ())
	if fs.isDir(TEMP_DIR) then
		fs.removeDir(TEMP_DIR)
	end
	fs.writeDir(TEMP_DIR)
	local success, result = pcall(callback :: any, TEMP_DIR)
	fs.removeDir(TEMP_DIR)

	if not success then
		error(result)
	end
end

local function copyDir(src: string, dest: string)
	if not fs.isDir(dest) then
		fs.writeDir(dest)
	end
	for _, entry in fs.readDir(src) do
		local srcPath = `{src}/{entry}`
		local destPath = `{dest}/{entry}`
		if fs.isDir(srcPath) then
			copyDir(srcPath, destPath)
		else
			fs.writeFile(destPath, fs.readFile(srcPath))
		end
	end
end

local function findFiles(root: string, name: string, results: { string }?): { string }
	local out = results or {}
	if not fs.isDir(root) then
		return out
	end
	for _, entry in fs.readDir(root) do
		local path = `{root}/{entry}`
		if fs.isDir(path) then
			findFiles(path, name, out)
		elseif entry == name then
			table.insert(out, path)
		end
	end
	return out
end

local function findAndReplace(filePath: string, match: string, replacement: string)
	local content = fs.readFile(filePath)
	content = content:gsub(match, replacement)
	fs.writeFile(filePath, content)
end

local function patchReact(packagesPath: string)
	local reactLinkers = findFiles(`{packagesPath}/_Index`, "React.lua")
	for _, reactLinker in reactLinkers do
		findAndReplace(reactLinker, `%["React"%]%["React"%]`, `["jsdotlua_react@17.2.1"]["react"]`)
	end
end

--[[
	Installs Foundation packages from an upstream packages directory.

	@param upstreamPath The path to the upstream packages directory
	@param dest The destination directory for the Foundation packages
	@param quiet Whether to suppress output
]]
local function installFoundation(upstreamPath: string, dest: string, _quiet: boolean?)
	withTempDir(function(tempDir)
		assert(fs.isDir(upstreamPath), `Could not find upstream packages at {upstreamPath}`)

		local packagesPath = `{tempDir}/Packages`
		copyDir(upstreamPath, packagesPath)

		patchReact(packagesPath)

		if not fs.isDir(dest) then
			fs.writeDir(dest)
		end
		copyDir(packagesPath, dest)
	end)
end

return installFoundation
