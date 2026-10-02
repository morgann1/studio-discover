--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const setScriptSourceAsync = require(StudioDiscover.Libraries.Core.setScriptSourceAsync)

--[[
	Replaces the ModuleScript named `name` under `parent` with a new one holding
		`source`. Returns the error when the write fails, in which case neither the old
		module nor the new one is left behind.
]]
const function replaceModuleAsync(parent: Instance, name: string, source: string): string?
	const existing = parent:FindFirstChild(name)
	if existing ~= nil then
		existing:Destroy()
	end

	const module = Instance.new("ModuleScript")
	module.Name = name
	module.Parent = parent

	const ok, err = setScriptSourceAsync(module, source)
	if not ok then
		module:Destroy()
		return err
	end

	return nil
end

return replaceModuleAsync
