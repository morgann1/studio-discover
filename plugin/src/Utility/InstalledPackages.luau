local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

export type InstalledPackage = {
	scope: string,
	name: string,
	version: string,
	realm: "shared" | "server",
	indexFolder: Folder,
}

local InstalledPackages = {}

local function parseIndexName(folderName: string): (string?, string?, string?)
	-- Format: "scope_name@version"
	local scopeAndName, version = folderName:match("^(.+)@(.+)$")
	if not scopeAndName then
		return nil, nil, nil
	end
	local scope, name = scopeAndName:match("^(.+)_(.+)$")
	if not scope then
		return nil, nil, nil
	end
	return scope, name, version
end

local function scanIndex(packagesFolder: Folder?, realm: "shared" | "server", out: { InstalledPackage })
	if not packagesFolder then
		return
	end
	local indexFolder = packagesFolder:FindFirstChild("_Index")
	if not indexFolder then
		return
	end
	for _, child in indexFolder:GetChildren() do
		local scope, name, version = parseIndexName(child.Name)
		if scope and name and version then
			table.insert(out, {
				scope = scope,
				name = name,
				version = version,
				realm = realm,
				indexFolder = child :: Folder,
			})
		end
	end
end

function InstalledPackages.list(): { InstalledPackage }
	local out = {}
	scanIndex(ReplicatedStorage:FindFirstChild("Packages"), "shared", out)
	scanIndex(ServerStorage:FindFirstChild("ServerPackages"), "server", out)
	return out
end

function InstalledPackages.map(): { [string]: InstalledPackage }
	local out = {}
	for _, pkg in InstalledPackages.list() do
		out[`{pkg.scope}/{pkg.name}`] = pkg
	end
	return out
end

return InstalledPackages
