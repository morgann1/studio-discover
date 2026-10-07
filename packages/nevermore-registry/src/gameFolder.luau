--!strict

--[[
	The folder Nevermore's loader bootstraps, as `nevermore init` lays a game out:
		ServerScriptService.Nevermore, holding the game's own modules in `game` and
		its packages in `node_modules`.
]]

const ServerScriptService = game:GetService("ServerScriptService")

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const getOrCreateFolder = require(StudioDiscover.Libraries.Core.getOrCreateFolder)

const NAME = "Nevermore"

-- Returns the game folder, or nil when the place has none. Reading never creates it.
const function find(): Folder?
	const folder = ServerScriptService:FindFirstChild(NAME)
	return if folder ~= nil and folder:IsA("Folder") then folder else nil
end

-- Returns `node_modules`, or nil when the place has none.
const function findNodeModules(): Folder?
	const root = find()
	const folder = if root ~= nil then root:FindFirstChild("node_modules") else nil
	return if folder ~= nil and folder:IsA("Folder") then folder else nil
end

-- Returns `node_modules`, creating it and the game folder. Call this only inside a ChangeHistory recording.
const function getNodeModules(): Folder
	return getOrCreateFolder(getOrCreateFolder(ServerScriptService, NAME), "node_modules")
end

const gameFolder = table.freeze({
	NAME = NAME,
	PATH = `ServerScriptService.{NAME}.node_modules`,
	find = find,
	findNodeModules = findNodeModules,
	getNodeModules = getNodeModules,
})

return gameFolder
