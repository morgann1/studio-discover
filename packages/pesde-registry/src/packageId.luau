--!strict

type Target = "roblox" | "roblox_server"

local function format(scope: string, name: string, version: string, target: Target): string
	return `{scope}/{name}@{version} {target}`
end

local function parse(packageId: string): (string?, string?, string?, string?)
	local namePart, versionAndTarget = packageId:match("^(.+)@(.+)$")
	if namePart == nil or versionAndTarget == nil then
		return nil, nil, nil, nil
	end
	local version, target = versionAndTarget:match("^(%S+)%s+(%S+)$")
	if version == nil or target == nil then
		return nil, nil, nil, nil
	end
	local scope, name = namePart:match("^(.+)/(.+)$")
	if scope == nil or name == nil then
		return nil, nil, nil, nil
	end
	return scope, name, version, target
end

return table.freeze({
	format = format,
	parse = parse,
})
