--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local types = require(StudioDiscover.Source.Installer.types)

type Realm = types.Realm

local PACKAGES_CONTAINER_NAME = ".pesde"

local function findPackagesFolder(realm: Realm): Folder?
	local parent = if realm == "server" then ServerStorage else ReplicatedStorage
	local name = if realm == "server" then "PesdeServerPackages" else "PesdePackages"
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
	local name = if realm == "server" then "PesdeServerPackages" else "PesdePackages"
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
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
	findPackagesFolder = findPackagesFolder,
	getPackagesFolder = getPackagesFolder,
	getOrCreateContainer = getOrCreateContainer,
	PACKAGES_CONTAINER_NAME = PACKAGES_CONTAINER_NAME,
})
