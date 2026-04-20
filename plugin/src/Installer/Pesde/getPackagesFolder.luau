--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local types = require(StudioDiscover.Source.Installer.types)

type Realm = types.Realm

local PACKAGES_CONTAINER_NAME = ".pesde"

local function getPackagesFolder(realm: Realm): Folder
	if realm == "server" then
		local folder = ServerStorage:FindFirstChild("PesdeServerPackages")
		if folder == nil then
			folder = Instance.new("Folder");
			(folder :: Folder).Name = "PesdeServerPackages"
			(folder :: Folder).Parent = ServerStorage
		end
		return folder :: Folder
	end

	local folder = ReplicatedStorage:FindFirstChild("PesdePackages")
	if folder == nil then
		folder = Instance.new("Folder");
		(folder :: Folder).Name = "PesdePackages"
		(folder :: Folder).Parent = ReplicatedStorage
	end
	return folder :: Folder
end

local function getOrCreateContainer(packagesFolder: Folder): Folder
	local container = packagesFolder:FindFirstChild(PACKAGES_CONTAINER_NAME)
	if container == nil then
		local created = Instance.new("Folder")
		created.Name = PACKAGES_CONTAINER_NAME
		created.Parent = packagesFolder
		container = created
	end
	return container :: Folder
end

return table.freeze({
	getPackagesFolder = getPackagesFolder,
	getOrCreateContainer = getOrCreateContainer,
	PACKAGES_CONTAINER_NAME = PACKAGES_CONTAINER_NAME,
})
