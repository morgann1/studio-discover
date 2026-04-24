--!strict

local ScriptEditorService = game:GetService("ScriptEditorService")

local function setScriptSource(script: LuaSourceContainer, content: string): (boolean, string?)
	local ok, err = pcall(function()
		ScriptEditorService:UpdateSourceAsync(script, function()
			return content
		end)
	end)
	if ok then
		return true, nil
	end
	return false, tostring(err)
end

return setScriptSource
