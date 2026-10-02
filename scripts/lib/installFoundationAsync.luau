--!strict

const fs = require("@std/fs")

const color = require("@scripts/lib/color")

-- roblox-packages links React by its own index name. We use the Wally React instead.
const UPSTREAM_REACT_LINK = '%["React"%]%["React"%]'
const WALLY_REACT_LINK = '["roblox_react@17.3.12"]["react"]'

-- A link to a versioned index entry, as in `PackageIndex["FoundationCloudAssets-31ab8d40-0.4.4"]`.
const VERSIONED_LINK = 'PackageIndex%["([%w_]+%-%x+%-[%d%.]+)"%]'

--[[
	roblox-packages names an index entry without its version suffix when it keeps only
		one version of a package, but leaves the links to it suffixed. Points each such
		link at the entry that exists.
]]
const function relinkUnversioned(source: string, entries: { [string]: true? }): string
	const replacements: { [string]: string } = {}
	for versioned in string.gmatch(source, VERSIONED_LINK) do
		const name = string.match(versioned, "^([%w_]+)%-")
		if name ~= nil and entries[versioned] == nil and entries[name] ~= nil then
			replacements[versioned] = `PackageIndex["{name}"]`
		end
	end

	-- A link with no replacement is left as it was.
	return (string.gsub(source, VERSIONED_LINK, replacements))
end

const function copyTreeAsync(source: string, destination: string, entries: { [string]: true? }): ()
	fs.createDirectory(destination, { makeParents = true })

	for _, entry in fs.listDirectory(source) do
		const from = `{source}/{entry.name}`
		const to = `{destination}/{entry.name}`

		if entry.type == "dir" then
			copyTreeAsync(from, to, entries)
		elseif string.match(entry.name, "%.lua$") ~= nil then
			local text = relinkUnversioned(fs.readFileToString(from), entries)
			if entry.name == "React.lua" then
				text = string.gsub(text, UPSTREAM_REACT_LINK, WALLY_REACT_LINK)
			end

			fs.writeStringToFile(to, text)
		else
			fs.copy(from, to)
		end
	end
end

--[[
	Copies the Packages tree that `roblox-packages install` produced into ours, with
		every React link pointed at the Wally React so the plugin runs one copy of it,
		and every link pointed at an index entry that exists.
]]
const function installFoundationAsync(upstreamPackagesPath: string, packagesPath: string): ()
	if not fs.exists(upstreamPackagesPath) then
		error(`roblox-packages produced nothing at {upstreamPackagesPath}`, 0)
	end

	print(color.bold(`> copy {upstreamPackagesPath} -> {packagesPath}`))

	const entries: { [string]: true? } = {}
	for _, entry in fs.listDirectory(`{upstreamPackagesPath}/_Index`) do
		entries[entry.name] = true
	end

	copyTreeAsync(upstreamPackagesPath, packagesPath, entries)
end

return installFoundationAsync
