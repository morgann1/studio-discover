--!strict

const ScriptEditorService = game:GetService("ScriptEditorService")

--[[
	Writes a script's source through ScriptEditorService, which has no cap on length.
		Assigning `.Source` directly fails past 200,000 characters.

	Returns false and the error instead of throwing.
]]
const function setScriptSourceAsync(script: LuaSourceContainer, content: string): (boolean, string?)
	const ok, err = pcall(function()
		ScriptEditorService:UpdateSourceAsync(script, function()
			return content
		end)
	end)

	if ok then
		return true, nil
	end

	return false, tostring(err)
end

return setScriptSourceAsync
