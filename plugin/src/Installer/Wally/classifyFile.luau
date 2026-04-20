--!strict

export type FileClass = "Script" | "LocalScript" | "ModuleScript" | "skip"

local function classifyFile(path: string): FileClass
	if string.match(path, "%.server%.luau?$") ~= nil then
		return "Script"
	elseif string.match(path, "%.client%.luau?$") ~= nil then
		return "LocalScript"
	elseif string.match(path, "%.luau?$") ~= nil then
		return "ModuleScript"
	end
	return "skip"
end

return classifyFile
