--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const createLogger = require(StudioDiscover.Libraries.Core.createLogger)

const logger = createLogger.createLogger("wally.installer.fileFilter")

-- What the wally CLI leaves out of a package when its manifest has no `include`.
const DEFAULT_EXCLUDE = table.freeze({
	".*",
	"wally.lock",
	"Packages",
	"ServerPackages",
	"DevPackages",
	"node_modules",
	"*.toml",
})

-- `**` crosses directories and `*` stays within one.
const function globToPattern(glob: string): string
	const escaped = glob:gsub("([%(%)%.%%%+%-%?%[%]%^%$])", "%%%1")
	const marked = escaped:gsub("%*%*", "\0")
	const withStars = marked:gsub("%*", "[^/]*")
	return (withStars:gsub("\0", ".*"))
end

--[[
	A glob matches whole path segments. One that starts with `/` is anchored to the
		package root, and any other can also match further down.
]]
const function matchesGlob(path: string, glob: string): boolean
	const anchored = string.sub(glob, 1, 1) == "/"
	const pattern = globToPattern(if anchored then string.sub(glob, 2) else glob)

	if string.match(path, `^{pattern}$`) ~= nil or string.match(path, `^{pattern}/`) ~= nil then
		return true
	elseif anchored then
		return false
	end

	return string.match(path, `/{pattern}/`) ~= nil or string.match(path, `/{pattern}$`) ~= nil
end

const function matchesAnyGlob(path: string, globs: { string }): boolean
	for _, glob in globs do
		if matchesGlob(path, glob) then
			return true
		end
	end

	return false
end

--[[
	Reads a string array such as `include = ["src", "default.project.json"]`,
		which may span lines. A missing key reads as empty.
]]
const function parseTomlStringArray(toml: string, key: string): { string }
	const items: { string } = {}
	const contents = string.match(toml, `{key}%s*=%s*%[([^%]]*)%]`)
	if contents == nil then
		return items
	end

	for value in string.gmatch(contents, '"([^"]*)"') do
		table.insert(items, value)
	end

	return items
end

--[[
	Builds the predicate that decides which archive paths install, from the
		package's `wally.toml`.

	A non-empty `include` list keeps only what it names. Otherwise everything
		installs except the default excludes and the manifest's `exclude` list.
]]
const function buildFileFilter(wallyToml: string?): (path: string) -> boolean
	const manifest = wallyToml or ""
	const include = parseTomlStringArray(manifest, "include")
	const extraExclude = parseTomlStringArray(manifest, "exclude")

	const exclude = table.clone(DEFAULT_EXCLUDE)
	table.move(extraExclude, 1, #extraExclude, #exclude + 1, exclude)

	if #include > 0 then
		logger.debug(`using include list ({#include} pattern(s))`)
	else
		logger.debug(`using exclude list ({#exclude} pattern(s))`)
	end

	return function(path: string): boolean
		if #include > 0 then
			const keep = matchesAnyGlob(path, include)
			if not keep then
				logger.debug(`drop "{path}" (not in include)`)
			end

			return keep
		end

		if matchesAnyGlob(path, exclude) then
			logger.debug(`drop "{path}" (matches exclude)`)
			return false
		end

		return true
	end
end

return buildFileFilter
