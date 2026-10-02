--!strict

local fs = require("@std/fs")

local color = require("@scripts/lib/color")

-- roblox-packages links React by its own index name. We use the Wally React instead.
local UPSTREAM_REACT_LINK = `%["React"%]%["React"%]`
local WALLY_REACT_LINK = `["jsdotlua_react@17.2.1"]["react"]`

local function copyTree(source: string, destination: string)
	fs.createDirectory(destination, { makeParents = true })

	for _, entry in fs.listDirectory(source) do
		local from = `{source}/{entry.name}`
		local to = `{destination}/{entry.name}`

		if entry.type == "dir" then
			copyTree(from, to)
		elseif entry.name == "React.lua" then
			local link = string.gsub(fs.readFileToString(from), UPSTREAM_REACT_LINK, WALLY_REACT_LINK)
			fs.writeStringToFile(to, link)
		else
			fs.copy(from, to)
		end
	end
end

--[[
	Copies the Packages tree that `roblox-packages install` produced into ours, with
		every React link pointed at the Wally React so the plugin runs one copy of it.
]]
local function installFoundation(upstreamPackagesPath: string, packagesPath: string)
	if not fs.exists(upstreamPackagesPath) then
		error(`roblox-packages produced nothing at {upstreamPackagesPath}`, 0)
	end

	print(color.bold(`> copy {upstreamPackagesPath} -> {packagesPath}`))
	copyTree(upstreamPackagesPath, packagesPath)
end

return installFoundation
