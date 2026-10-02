--!strict

const fs = require("@std/fs")

const project = require("@root/project")

-- Reads the plugin's version from `plugin/wally.toml`, the one that builds are stamped with.
const function readPluginVersionAsync(): string
	const contents = fs.readFileToString(project.WALLY_TOML_PATH)

	const version = string.match(contents, 'version%s*=%s*"([^"]+)"')
	if version == nil then
		error(`Could not read the version from {project.WALLY_TOML_PATH}`, 0)
	end

	return version
end

return readPluginVersionAsync
