--!strict

--[[
	The name a package gets as its folder under `Packages/_Index`.

	This is wally's format, not ours. `package_id_file_name` in
	`src/installation.rs` builds `"{scope}_{name}@{version}"`, and a place
	installed by the wally CLI has folders named exactly that, so Discover has to
	produce and read the same thing to share an `_Index` with it.

	The greedy split in `parse` is safe against anything wally can produce.
	`validate_scope` and `validate_name` in `src/package_name.rs` allow only
	lowercase letters, digits and `-`, so neither half can contain the `_` that
	separates them. On a malformed id with several underscores the split takes
	the last one, which is wally's own ambiguity rather than a case worth
	inventing behavior for.
]]

local function format(scope: string, name: string, version: string): string
	return `{scope}_{name}@{version}`
end

local function parse(packageId: string): (string?, string?, string?)
	local scopeAndName, version = packageId:match("^(.+)@(.+)$")
	if scopeAndName == nil then
		return nil, nil, nil
	end
	local scope, name = scopeAndName:match("^(.+)_(.+)$")
	if scope == nil then
		return nil, nil, nil
	end
	return scope, name, version
end

return table.freeze({
	format = format,
	parse = parse,
})
