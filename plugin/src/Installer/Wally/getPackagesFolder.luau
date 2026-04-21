--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local types = require(StudioDiscover.Source.Installer.types)

type Realm = types.Realm

local function findPackagesFolder(realm: Realm): Folder?
	local parent = if realm == "server" then ServerStorage else ReplicatedStorage
	local name = if realm == "server" then "ServerPackages" else "Packages"
	local folder = parent:FindFirstChild(name)
	if folder == nil or not folder:IsA("Folder") then
		return nil
	end
	return folder :: Folder
end

local function getPackagesFolder(realm: Realm): Folder
	local existing = findPackagesFolder(realm)
	if existing ~= nil then
		return existing
	end
	local parent = if realm == "server" then ServerStorage else ReplicatedStorage
	local name = if realm == "server" then "ServerPackages" else "Packages"
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function getOrCreateIndex(packagesFolder: Folder): Folder
	local index = packagesFolder:FindFirstChild("_Index")
	if index == nil then
		index = Instance.new("Folder");
		(index :: Folder).Name = "_Index"
		(index :: Folder).Parent = packagesFolder
	end
	return index :: Folder
end

return table.freeze({
	findPackagesFolder = findPackagesFolder,
	getPackagesFolder = getPackagesFolder,
	getOrCreateIndex = getOrCreateIndex,
})
