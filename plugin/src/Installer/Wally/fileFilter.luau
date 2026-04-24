--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local createLogger = require(StudioDiscover.Source.Util.createLogger)

local logger = createLogger.createLogger("wally.installer.fileFilter")

local DEFAULT_EXCLUDE: { string } = {
	".*",
	"wally.lock",
	"Packages",
	"ServerPackages",
	"DevPackages",
	"node_modules",
	"*.toml",
}

local function globToPattern(glob: string): string
	local pattern = glob:gsub("([%(%)%.%%%+%-%?%[%]%^%$])", function(c)
		return "%" .. c
	end)
	pattern = pattern:gsub("%*%*", "\0")
	pattern = pattern:gsub("%*", "[^/]*")
	pattern = pattern:gsub("\0", ".*")
	return pattern
end

local function matchesAnyGlob(path: string, globs: { string }): boolean
	for _, glob in globs do
		local anchored = string.sub(glob, 1, 1) == "/"
		local cleanGlob = if anchored then string.sub(glob, 2) else glob
		local pattern = globToPattern(cleanGlob)
		if anchored then
			if string.match(path, "^" .. pattern .. "$") ~= nil or string.match(path, "^" .. pattern .. "/") ~= nil then
				return true
			end
		else
			if
				string.match(path, "^" .. pattern .. "$") ~= nil
				or string.match(path, "^" .. pattern .. "/") ~= nil
				or string.match(path, "/" .. pattern .. "/") ~= nil
				or string.match(path, "/" .. pattern .. "$") ~= nil
			then
				return true
			end
		end
	end
	return false
end

local function parseTomlStringArray(toml: string, key: string): { string }?
	local contents = string.match(toml, key .. "%s*=%s*%[([^%]]*)%]")
	if contents == nil then
		return nil
	end
	local items: { string } = {}
	for value in string.gmatch(contents, '"([^"]*)"') do
		table.insert(items, value)
	end
	return items
end

local function buildFileFilter(wallyToml: string?): (string) -> boolean
	local include: { string }? = nil
	local exclude = table.clone(DEFAULT_EXCLUDE)

	if wallyToml ~= nil then
		include = parseTomlStringArray(wallyToml, "include")
		local extraExclude = parseTomlStringArray(wallyToml, "exclude")
		if extraExclude ~= nil then
			for _, pattern in extraExclude do
				table.insert(exclude, pattern)
			end
		end
	end

	if include ~= nil then
		logger.debug(`using include list ({#include} pattern(s))`)
	else
		logger.debug(`using exclude list ({#exclude} pattern(s))`)
	end

	return function(path: string): boolean
		if include ~= nil and #include > 0 then
			local keep = matchesAnyGlob(path, include)
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
