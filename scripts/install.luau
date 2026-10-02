--!strict

--[[
	Gets a fresh clone ready to build, test, and analyze. Safe to run again at any
		time, and the fix when module resolution looks broken.

	Usage: lute scripts/install.luau
]]

const process = require("@lute/process")

const applyPatchesAsync = require("@scripts/lib/applyPatchesAsync")
const codegenAsync = require("@scripts/lib/codegenAsync")
const installFoundationAsync = require("@scripts/lib/installFoundationAsync")
const project = require("@root/project")
const runAsync = require("@scripts/lib/runAsync")

-- Roblox-only packages that are not on Wally, pulled from a Roblox client build.
const ROBLOX_PACKAGES = table.freeze({
	"Foundation",
	"FoundationImages",
	"BuilderIcons",
	"Otter",
	"ReactOtter",
	"Promise",
	"Dash",
	"Motion",
})

-- The `@lute` and `@std` aliases in .luaurc resolve to these generated typedefs.
runAsync("lute", { "setup" })

runAsync("wally", { "install" }, { cwd = project.PLUGIN_PATH })

-- wally-package-types reads the sourcemap, which needs the generated build config.
codegenAsync({ sourcemap = true })
runAsync(
	"wally-package-types",
	{ "--sourcemap", `../{project.SOURCEMAP_PATH}`, "Packages" },
	{ cwd = project.PLUGIN_PATH }
)

const tempPath = process.env.TEMP or process.env.TMPDIR or "/tmp"
const robloxPackagesPath = `{tempPath}/roblox-packages`

const robloxPackagesArgs = { "install", robloxPackagesPath, "--version", project.ROBLOX_PACKAGES_VERSION }
for _, name in ROBLOX_PACKAGES do
	table.insert(robloxPackagesArgs, "-d")
	table.insert(robloxPackagesArgs, name)
end

runAsync("roblox-packages", robloxPackagesArgs)
installFoundationAsync(`{robloxPackagesPath}/Packages`, project.VENDORED_PACKAGES_PATH)

applyPatchesAsync()

-- Map the Roblox packages too, so the editor resolves them.
codegenAsync({ sourcemap = true })
