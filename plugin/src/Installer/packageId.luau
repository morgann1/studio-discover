--!strict

-- Package IDs use the `{scope}_{name}@{version}` shape, matching Wally's
-- `package_id_file_name` convention. Used as `_Index` folder names.

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
