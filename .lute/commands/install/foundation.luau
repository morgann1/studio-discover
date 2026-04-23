--[[
	Foundation Package Installation

	Installs Foundation packages from an upstream packages directory.
	Patches React references to point to the Wally-installed React package.
]]

local fs = require("@lute/fs")

local TEMP_DIR = "tmp"

local function isDir(path: string): boolean
	return fs.exists(path) and fs.type(path) == "dir"
end

local function readFile(path: string): string
	local handle = fs.open(path, "r")
	local contents = fs.read(handle)
	fs.close(handle)
	return contents
end

local function writeFile(path: string, contents: string)
	local handle = fs.open(path, "w")
	fs.write(handle, contents)
	fs.close(handle)
end

local function removeDirRecursive(path: string)
	for _, entry in fs.listdir(path) do
		local child = `{path}/{entry.name}`
		if entry.type == "dir" then
			removeDirRecursive(child)
		else
			fs.remove(child)
		end
	end
	fs.rmdir(path)
end

local function withTempDir(callback: (path: string) -> ())
	if isDir(TEMP_DIR) then
		removeDirRecursive(TEMP_DIR)
	end
	fs.mkdir(TEMP_DIR)
	local success, result = pcall(callback :: any, TEMP_DIR)
	removeDirRecursive(TEMP_DIR)

	if not success then
		error(result)
	end
end

local function copyDir(src: string, dest: string)
	if not isDir(dest) then
		fs.mkdir(dest)
	end
	for _, entry in fs.listdir(src) do
		local srcPath = `{src}/{entry.name}`
		local destPath = `{dest}/{entry.name}`
		if entry.type == "dir" then
			copyDir(srcPath, destPath)
		else
			writeFile(destPath, readFile(srcPath))
		end
	end
end

local function findFiles(root: string, name: string, results: { string }?): { string }
	local out = results or {}
	if not isDir(root) then
		return out
	end
	for _, entry in fs.listdir(root) do
		local path = `{root}/{entry.name}`
		if entry.type == "dir" then
			findFiles(path, name, out)
		elseif entry.name == name then
			table.insert(out, path)
		end
	end
	return out
end

local function findAndReplace(filePath: string, match: string, replacement: string)
	local content = readFile(filePath)
	content = content:gsub(match, replacement)
	writeFile(filePath, content)
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
		assert(isDir(upstreamPath), `Could not find upstream packages at {upstreamPath}`)

		local packagesPath = `{tempDir}/Packages`
		copyDir(upstreamPath, packagesPath)

		patchReact(packagesPath)

		if not isDir(dest) then
			fs.mkdir(dest)
		end
		copyDir(packagesPath, dest)
	end)
end

return installFoundation
