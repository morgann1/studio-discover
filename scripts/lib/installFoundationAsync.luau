--!strict

const fs = require("@std/fs")

const color = require("@scripts/lib/color")

-- roblox-packages links React by its own index name. We use the Wally React instead.
const UPSTREAM_REACT_LINK = '%["React"%]%["React"%]'
const WALLY_REACT_LINK = '["jsdotlua_react@17.2.1"]["react"]'

const function copyTreeAsync(source: string, destination: string): ()
	fs.createDirectory(destination, { makeParents = true })

	for _, entry in fs.listDirectory(source) do
		const from = `{source}/{entry.name}`
		const to = `{destination}/{entry.name}`

		if entry.type == "dir" then
			copyTreeAsync(from, to)
		elseif entry.name == "React.lua" then
			const link = string.gsub(fs.readFileToString(from), UPSTREAM_REACT_LINK, WALLY_REACT_LINK)
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
const function installFoundationAsync(upstreamPackagesPath: string, packagesPath: string): ()
	if not fs.exists(upstreamPackagesPath) then
		error(`roblox-packages produced nothing at {upstreamPackagesPath}`, 0)
	end

	print(color.bold(`> copy {upstreamPackagesPath} -> {packagesPath}`))
	copyTreeAsync(upstreamPackagesPath, packagesPath)
end

return installFoundationAsync
