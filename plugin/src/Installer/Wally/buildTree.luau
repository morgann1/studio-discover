--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local classifyFile = require(StudioDiscover.Source.Installer.Wally.classifyFile)
local createLogger = require(StudioDiscover.Source.Util.createLogger)

local logger = createLogger.createLogger("installer.buildTree")

export type Entry = {
	path: string,
	content: string,
}

local function getInstanceName(filename: string): string
	local instanceName = filename
	instanceName = instanceName:gsub("%.server%.luau?$", "")
	instanceName = instanceName:gsub("%.client%.luau?$", "")
	instanceName = instanceName:gsub("%.luau?$", "")
	return instanceName
end

local function buildTree(entries: { Entry }, packageName: string): Instance
	logger.debug(`building tree for "{packageName}" ({#entries} entries)`)
	local root: any = Instance.new("Folder")
	root.Name = packageName

	local skipped = 0
	local moduleCount = 0
	local initPromotions = 0

	table.sort(entries, function(a, b)
		local aIsInit = a.path:match("init%.luau?$") ~= nil
		local bIsInit = b.path:match("init%.luau?$") ~= nil
		if aIsInit ~= bIsInit then
			return not aIsInit
		end
		return a.path < b.path
	end)

	for _, entry in entries do
		local className = classifyFile(entry.path)
		if className == "skip" then
			skipped += 1
			continue
		end

		local parts = string.split(entry.path, "/")
		local startIdx = if #parts > 1 then 2 else 1

		local parent: any = root
		for i = startIdx, #parts - 1 do
			local folderName = parts[i]
			if folderName == "" then
				continue
			end
			local existing = parent:FindFirstChild(folderName)
			if existing == nil then
				existing = Instance.new("Folder")
				existing.Name = folderName
				existing.Parent = parent
			end
			parent = existing
		end

		local fileName = parts[#parts]
		if fileName == "" then
			continue
		end

		local instanceName = getInstanceName(fileName)

		if instanceName == "init" then
			if parent:IsA("Folder") then
				local moduleScript: any = Instance.new(className :: any)
				moduleScript.Name = parent.Name
				moduleScript.Source = entry.content

				if parent == root then
					for _, child in parent:GetChildren() do
						child.Parent = moduleScript
					end
					parent:Destroy()
					root = moduleScript
				else
					moduleScript.Parent = parent.Parent
					for _, child in parent:GetChildren() do
						child.Parent = moduleScript
					end
					parent:Destroy()
				end
				initPromotions += 1
				moduleCount += 1
			end
		else
			local inst: any = Instance.new(className :: any)
			inst.Name = instanceName
			inst.Source = entry.content
			inst.Parent = parent
			moduleCount += 1
		end
	end

	logger.debug(
		`built "{packageName}" tree: {moduleCount} module(s), {initPromotions} init promotion(s), {skipped} skipped`
	)
	return root
end

return buildTree
