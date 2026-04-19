--!strict

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

-- wally.toml exposes `include` / `exclude` arrays. We parse them out with a
-- narrow regex rather than importing a full TOML parser.
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

-- Returns a predicate for paths relative to the package root: true to keep.
-- If `include` is set in wally.toml, only matching paths are kept. Otherwise
-- the default exclude list plus any user `exclude` patterns filter things out.
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

	return function(path: string): boolean
		if include ~= nil and #include > 0 then
			return matchesAnyGlob(path, include)
		end
		if matchesAnyGlob(path, exclude) then
			return false
		end
		return true
	end
end

return buildFileFilter
