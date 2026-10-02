--!strict

export type ScriptClass = "Script" | "LocalScript" | "ModuleScript"

export type FileClass = ScriptClass | "skip"

-- Returns the class of script an archive file becomes, or "skip" for anything that is not Luau source.
const function classifyFile(path: string): FileClass
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
