--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local classifyFile = require(StudioDiscover.Source.Installer.classifyFile)

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

-- Walks a flat list of path/content entries and builds a Folder/ModuleScript
-- tree. An `init.luau` inside a folder promotes that folder to a ModuleScript
-- whose children are the folder's other contents — matches Rojo's init-rule.
-- Returns either a Folder or a ModuleScript depending on whether the root
-- itself had an `init` file.
local function buildTree(entries: { Entry }, packageName: string): Instance
	local root: any = Instance.new("Folder")
	root.Name = packageName

	-- Process non-init entries first so subsequent init promotions have
	-- siblings to move.
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
			end
		else
			local inst: any = Instance.new(className :: any)
			inst.Name = instanceName
			inst.Source = entry.content
			inst.Parent = parent
		end
	end

	return root
end

return buildTree
