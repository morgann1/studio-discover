--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local types = require(StudioDiscover.Source.Installer.types)

type Realm = types.Realm

-- Returns (and creates if missing) the top-level packages folder for a realm.
-- Shared packages live in ReplicatedStorage, server packages in ServerStorage.
local function getPackagesFolder(realm: Realm): Folder
	if realm == "server" then
		local folder = ServerStorage:FindFirstChild("ServerPackages")
		if folder == nil then
			folder = Instance.new("Folder");
			(folder :: Folder).Name = "ServerPackages"
			(folder :: Folder).Parent = ServerStorage
		end
		return folder :: Folder
	end

	local folder = ReplicatedStorage:FindFirstChild("Packages")
	if folder == nil then
		folder = Instance.new("Folder");
		(folder :: Folder).Name = "Packages"
		(folder :: Folder).Parent = ReplicatedStorage
	end
	return folder :: Folder
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
	getPackagesFolder = getPackagesFolder,
	getOrCreateIndex = getOrCreateIndex,
})
