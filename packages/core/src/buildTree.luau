--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const classifyFile = require(StudioDiscover.Libraries.Core.classifyFile)
const createLogger = require(StudioDiscover.Libraries.Core.createLogger)
const exhaustiveMatch = require(StudioDiscover.Libraries.Core.exhaustiveMatch)

const logger = createLogger.createLogger("core.buildTree")

export type Entry = {
	read path: string,
	read content: string,
}

-- A script the tree holds and the source it still needs, which the caller writes through `setScriptSourceAsync`.
export type PendingSource = {
	read script: LuaSourceContainer,
	read path: string,
	read content: string,
}

const function getInstanceName(fileName: string): string
	return fileName:match("^(.-)%.server%.luau?$")
		or fileName:match("^(.-)%.client%.luau?$")
		or fileName:match("^(.-)%.luau?$")
		or fileName
end

const function createScript(className: classifyFile.ScriptClass): LuaSourceContainer
	if className == "Script" then
		return Instance.new("Script")
	elseif className == "LocalScript" then
		return Instance.new("LocalScript")
	elseif className == "ModuleScript" then
		return Instance.new("ModuleScript")
	end

	return exhaustiveMatch(className)
end

--[[
	Builds an archive's files into an Instance tree named `packageName`, dropping the
		archive's top-level directory and anything that is not Luau source.

	An init file turns its folder into a script named for the folder. Entries can
		come in any order, since a file whose folder is already a script lands inside
		that script.

	The scripts come back without source, as `pending`, since a source write can
		fail and the caller decides what a failure means.
]]
const function buildTree(entries: { Entry }, packageName: string): (Instance, { PendingSource })
	logger.debug(`building tree for "{packageName}" ({#entries} entries)`)

	local root: Instance = Instance.new("Folder")
	root.Name = packageName

	const pending: { PendingSource } = {}
	local skipped = 0
	local moduleCount = 0
	local initPromotions = 0

	for _, entry in entries do
		const className = classifyFile(entry.path)
		if className == "skip" then
			skipped += 1
			continue
		end

		const parts = string.split(entry.path, "/")

		local parent = root
		for index = 2, #parts - 1 do
			const folderName = parts[index]
			if folderName == "" then
				continue
			end

			const existing = parent:FindFirstChild(folderName)
			if existing ~= nil then
				parent = existing
				continue
			end

			const folder = Instance.new("Folder")
			folder.Name = folderName
			folder.Parent = parent
			parent = folder
		end

		const instanceName = getInstanceName(parts[#parts])
		if instanceName ~= "init" then
			const container = createScript(className)
			container.Name = instanceName
			container.Parent = parent

			table.insert(pending, { script = container, path = entry.path, content = entry.content })
			moduleCount += 1
			continue
		end

		-- A folder an earlier init file already promoted has nothing left to promote.
		if not parent:IsA("Folder") then
			continue
		end

		const container = createScript(className)
		container.Name = parent.Name
		table.insert(pending, { script = container, path = entry.path, content = entry.content })

		for _, child in parent:GetChildren() do
			child.Parent = container
		end

		if parent == root then
			root = container
		else
			container.Parent = parent.Parent
		end
		parent:Destroy()

		initPromotions += 1
		moduleCount += 1
	end

	logger.debug(
		`built "{packageName}" tree: {moduleCount} module(s), {initPromotions} init promotion(s), {skipped} skipped`
	)

	return root, pending
end

return buildTree
