--!strict

export type ScriptClass = "Script" | "LocalScript" | "ModuleScript"

-- A `.rbxm` or `.rbxmx` model, which becomes the instance it holds.
export type FileClass = ScriptClass | "Model" | "skip"

-- Returns what an archive file becomes, or "skip" for anything that is neither Luau source nor a model.
const function classifyFile(path: string): FileClass
	if string.match(path, "%.server%.luau?$") ~= nil then
		return "Script"
	elseif string.match(path, "%.client%.luau?$") ~= nil then
		return "LocalScript"
	elseif string.match(path, "%.luau?$") ~= nil then
		return "ModuleScript"
	elseif string.match(path, "%.rbxmx?$") ~= nil then
		return "Model"
	end

	return "skip"
end

return classifyFile
