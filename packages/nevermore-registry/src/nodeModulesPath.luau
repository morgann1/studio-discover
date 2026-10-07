--!strict

--[[
	Where npm puts a package inside `node_modules`: the scope folder, such as
		"@quenty", when the name has a scope, and the folder named for the rest, such
		as "maid".
]]
const function nodeModulesPath(name: string): (string?, string)
	const scope, folderName = name:match("^(@[^/]+)/(.+)$")
	if scope ~= nil and folderName ~= nil then
		return scope, folderName
	end

	return nil, name
end

return nodeModulesPath
