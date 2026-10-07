--!strict

const SerializationService = game:GetService("SerializationService")

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const buildTree = require(StudioDiscover.Libraries.Core.buildTree)
const setScriptSourceAsync = require(StudioDiscover.Libraries.Core.setScriptSourceAsync)

--[[
	Swaps a model's placeholder for the one instance the model holds, named for the
		placeholder, as Rojo names a model for its file. Returns the error when the
		model doesn't load or holds anything but one instance.
]]
const function placeModelAsync(placeholder: Folder, content: string): string?
	const ok, result = pcall(function()
		return SerializationService:DeserializeInstancesAsync(buffer.fromstring(content))
	end)

	if not ok then
		return tostring(result)
	elseif #result ~= 1 then
		for _, instance in result do
			instance:Destroy()
		end

		return `a model must hold one instance, and this one holds {#result}`
	end

	const instance = result[1]
	instance.Name = placeholder.Name
	instance.Parent = placeholder.Parent
	placeholder:Destroy()

	return nil
end

--[[
	Writes the sources and models `buildTree` left pending, stopping at the first
		that fails. Returns that failure as "path: error", or nil when every write
		succeeded.
]]
const function writePendingSourcesAsync(pending: { buildTree.PendingSource }): string?
	for _, item in pending do
		local err: string? = nil
		if item.kind == "script" then
			const ok, writeError = setScriptSourceAsync(item.script, item.content)
			err = if ok then nil else writeError
		else
			err = placeModelAsync(item.placeholder, item.content)
		end

		if err ~= nil then
			return `{item.path}: {err}`
		end
	end

	return nil
end

return writePendingSourcesAsync
