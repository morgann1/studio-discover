--!strict

--[[
	Gets a fresh clone ready to build, test, and analyze. Safe to run again at any
		time, and the fix when module resolution looks broken.

	Usage: lute scripts/install.luau
]]

local process = require("@lute/process")

local applyPatches = require("@scripts/lib/applyPatches")
local codegen = require("@scripts/lib/codegen")
local installFoundation = require("@scripts/lib/installFoundation")
local project = require("@root/project")
local run = require("@scripts/lib/run")

-- Roblox-only packages that are not on Wally, pulled from a Roblox client build.
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

-- The `@lute` and `@std` aliases in .luaurc resolve to these generated typedefs.
run("lute", { "setup" })

run("wally", { "install" }, { cwd = project.PLUGIN_PATH })

-- wally-package-types reads the sourcemap, which needs the generated build config.
codegen({ sourcemap = true })
run("wally-package-types", { "--sourcemap", `../{project.SOURCEMAP_PATH}`, "Packages" }, { cwd = project.PLUGIN_PATH })

local tempPath = process.env.TEMP or process.env.TMPDIR or "/tmp"
local robloxPackagesPath = `{tempPath}/roblox-packages`

local robloxPackagesArgs = { "install", robloxPackagesPath, "--version", project.ROBLOX_PACKAGES_VERSION }
for _, name in ROBLOX_PACKAGES do
	table.insert(robloxPackagesArgs, "-d")
	table.insert(robloxPackagesArgs, name)
end

run("roblox-packages", robloxPackagesArgs)
installFoundation(`{robloxPackagesPath}/Packages`, project.VENDORED_PACKAGES_PATH)

applyPatches()

-- Map the Roblox packages too, so the editor resolves them.
codegen({ sourcemap = true })
