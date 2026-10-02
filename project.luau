--!strict

--[[
	Paths and pins shared by the scripts in `scripts/`.

	Every script runs from the repo root, so paths here are relative to it.
]]

const project = table.freeze({
	PROJECT_MODULE_PATH = "project.luau",
	SCRIPTS_PATH = "scripts",
	TASKS_PATH = "scripts/tasks",
	PACKAGES_PATH = "packages",
	PLUGIN_PATH = "plugin",
	PLUGIN_BIN_PATH = "plugin/bin",
	PLUGIN_SRC_PATH = "plugin/src",

	PROJECT_PATH = "plugin/default.project.json",
	TESTS_PROJECT_PATH = "plugin/test.project.json",
	WALLY_TOML_PATH = "plugin/wally.toml",
	VENDORED_PACKAGES_PATH = "plugin/Packages",
	VENDORED_DEV_PACKAGES_PATH = "plugin/DevPackages",
	PATCHES_PATH = "plugin/patches",

	GENERATED_PATH = "plugin/generated",
	BUILD_CONFIG_PATH = "plugin/generated/buildConfig.luau",
	SOURCEMAP_PATH = "plugin/generated/sourcemap.json",
	GLOBAL_DEFS_PATH = "plugin/generated/globalTypes.d.luau",

	-- The last luau-lsp commit to touch scripts/globalTypes.d.luau when this was pinned.
	LUAU_LSP_COMMIT = "6ebc3e53ab59b40d45bb42db5ca5e9c2a87a1c96",
	LUAU_LSP_GLOBAL_TYPES_SHA256 = "bbaab2025896fa3b6ea8bbcc09dcb8b72f777b264ab95b5086374dd3672574ef",

	-- The Roblox client version that roblox-packages pulls Foundation and friends from.
	ROBLOX_PACKAGES_VERSION = "0.716.0.7160873",
})

return project
