--!strict

-- Returns the Folder named `name` under `parent`, creating it when there is none.
const function getOrCreateFolder(parent: Instance, name: string): Folder
	const existing = parent:FindFirstChild(name)
	if existing ~= nil and existing:IsA("Folder") then
		return existing
	end

	const folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

return getOrCreateFolder
