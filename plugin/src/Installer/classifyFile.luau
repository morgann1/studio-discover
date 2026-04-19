--!strict

export type FileClass = "Script" | "LocalScript" | "ModuleScript" | "skip"

-- Suffix-based classification matches Rojo's naming convention:
--   *.server.luau → Script (server context)
--   *.client.luau → LocalScript (client context)
--   *.luau       → ModuleScript (plain require target)
-- Non-script files are skipped; the installer only materializes Luau source.
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
