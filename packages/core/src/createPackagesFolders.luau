--!strict

const ReplicatedStorage = game:GetService("ReplicatedStorage")
const ServerStorage = game:GetService("ServerStorage")

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const getOrCreateFolder = require(StudioDiscover.Libraries.Core.getOrCreateFolder)
const types = require(StudioDiscover.Libraries.Core.types)

-- Where one registry writes: the folder name for each realm, and the name of the index inside it.
export type Names = {
	read shared: string,
	read server: string,
	read index: string,
}

export type PackagesFolders = {
	-- Returns the realm's packages folder, or nil when the place has none. Reading never creates it.
	read find: (realm: types.Realm) -> Folder?,
	-- Returns the realm's packages folder, creating it. Call this only inside a ChangeHistory recording.
	read get: (realm: types.Realm) -> Folder,
	-- Returns the realm's index, or nil when the place has none.
	read findIndex: (realm: types.Realm) -> Instance?,
	-- Returns the realm's index, creating it and the packages folder above it.
	read getIndex: (realm: types.Realm) -> Folder,
}

--[[
	Returns the folder lookups for one registry. The shared folder lives in
		ReplicatedStorage and the server folder in ServerStorage.
]]
const function createPackagesFolders(names: Names): PackagesFolders
	const function location(realm: types.Realm): (Instance, string)
		if realm == "server" then
			return ServerStorage, names.server
		end

		return ReplicatedStorage, names.shared
	end

	const function find(realm: types.Realm): Folder?
		const parent, name = location(realm)
		const folder = parent:FindFirstChild(name)
		if folder == nil or not folder:IsA("Folder") then
			return nil
		end

		return folder
	end

	const function get(realm: types.Realm): Folder
		const parent, name = location(realm)
		return getOrCreateFolder(parent, name)
	end

	const function findIndex(realm: types.Realm): Instance?
		const folder = find(realm)
		return if folder ~= nil then folder:FindFirstChild(names.index) else nil
	end

	const function getIndex(realm: types.Realm): Folder
		return getOrCreateFolder(get(realm), names.index)
	end

	return table.freeze({
		find = find,
		get = get,
		findIndex = findIndex,
		getIndex = getIndex,
	})
end

return createPackagesFolders
