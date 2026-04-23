--[[
	Install Command

	Installs all packages: Wally packages, package types, and Foundation.
]]

local fs = require("@lute/fs")
local io = require("@lute/io")
local process = require("@lute/process")

local applyPatches = require("./install/patches")
local codegen = require("./codegen")
local color = require("../utils/color")
local exec = require("../lib/process/exec")
local installFoundation = require("./install/foundation")
local rojo = require("../lib/project/rojo")

local install = {}

-- Metadata for help command
install.name = "install"
install.description = "Installs all packages (Wally, package types, Foundation)"
install.usage = "lute run install [--quiet]"

-- Argument definitions for CLI parsing
install.arguments = {
	{
		name = "quiet",
		kind = "flag",
		options = {
			help = "Suppress output",
			aliases = { "q" },
		},
	},
}

local PROJECT_FILE = "plugin/default.project.json"
local SOURCEMAP_PATH = "plugin/generated/sourcemap.json"
local VERSION_PIN = "0.716.0.7160873"
local PACKAGE_DIRS = {
	"Packages",
	-- "DevPackages",
}
local ROBLOX_PACKAGES = {
	"Foundation",
	"FoundationImages",
	"BuilderIcons",
	"Otter",
	"ReactOtter",
	"Promise",
	"Dash",
	"Motion",
}

local function isDir(path: string): boolean
	return fs.exists(path) and fs.type(path) == "dir"
end

local function runWallyInstall(): (boolean, string)
	local result = process.run({ "wally", "install" }, {
		cwd = "plugin",
	})
	if not result.ok then
		return false, result.stderr
	end
	return true, result.stdout
end

local function runPackageTypes(dirPath: string, sourcemapPath: string): (boolean, string)
	local result = process.run({
		"wally-package-types",
		"--sourcemap",
		`../{sourcemapPath}`,
		dirPath,
	}, {
		cwd = "plugin",
	})

	if not result.ok then
		return false, result.stderr
	end
	return true, result.stdout
end

export type Options = {
	quiet: boolean?,
}

--[[
	Installs all packages.

	@param options Configuration options
	@return True if successful, false otherwise
]]
function install.run(options_: Options?): boolean
	local options: Options = options_ or {}
	local quiet = if options.quiet ~= nil then options.quiet else false

	if not quiet then
		print(color.dim("Installing Wally packages..."))
	end

	local installResult, installStdout = runWallyInstall()
	if not installResult then
		print(color.bold(color.red("Failed to install packages")))
		io.write(installStdout)
		return false
	end

	if not isDir("plugin/generated") then
		fs.mkdir("plugin/generated")
	end

	-- Seed the generated buildConfig module before the sourcemap runs so rojo
	-- can resolve its $path entry in default.project.json.
	local codegenSuccess = codegen.run({ quiet = quiet, generateSourcemap = false })
	if not codegenSuccess then
		return false
	end

	local sourcemapResult, sourcemapStdout = rojo.sourcemap({
		projectFile = PROJECT_FILE,
		output = SOURCEMAP_PATH,
		includeNonScripts = true,
	})
	if not sourcemapResult then
		print(color.bold(color.red("Failed to generate project sourcemap")))
		io.write(sourcemapStdout)
		return false
	end

	for _, dir in PACKAGE_DIRS do
		local result, stdout = runPackageTypes(dir, SOURCEMAP_PATH)
		if not result then
			print(color.bold(color.red("Failed to generate package types for " .. dir)))
			io.write(stdout)
			return false
		end
	end

	if not quiet then
		print(color.bold(color.white("Successfully installed Wally packages!")))
	end

	-- Install Roblox packages to a temp directory and then extract Foundation.
	-- Use platform temp dir (TEMP on Windows, TMPDIR on Unix), falling back to /tmp.
	local tempBase = process.env.TEMP or process.env.TMPDIR or "/tmp"
	local robloxPackagesPath = `{tempBase}/roblox-packages`
	local robloxPackagesArgs = {
		"install",
		robloxPackagesPath,
		"--version",
		VERSION_PIN,
	}
	for _, pkg in ROBLOX_PACKAGES do
		table.insert(robloxPackagesArgs, "-d")
		table.insert(robloxPackagesArgs, pkg)
	end
	exec.run("roblox-packages", robloxPackagesArgs)

	if not quiet then
		print(color.dim("Installing Foundation packages..."))
	end

	installFoundation(`{robloxPackagesPath}/Packages`, "plugin/Packages", quiet)

	if not quiet then
		print(color.bold(color.white("Successfully installed Foundation packages!")))
	end

	-- Apply patches after all packages (Wally + Foundation) are installed
	if not quiet then
		print(color.dim("Applying package patches..."))
	end

	local patchResult = applyPatches(quiet)
	if not patchResult then
		print(color.bold(color.red("Failed to apply package patches")))
		return false
	end

	if not quiet then
		print(color.bold(color.white("Successfully applied package patches!")))
	end

	return true
end

return install
