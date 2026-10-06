--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const installerTypes = require(StudioDiscover.Source.Installer.types)
const plural = require(StudioDiscover.Source.Util.plural)

--[[
	The notice for an operation that finished, as in "Removed Promise with 1 warning.
		Undo with Ctrl+Z.", or nil when it failed, since a failure already shows where
		it was started. `done` says what happened and `hint` follows it.
]]
const function successNotice(result: installerTypes.OperationResult, done: string, hint: string?): string?
	if not result.ok then
		return nil
	end

	const warnings = if #result.failures > 0 then ` with {plural(#result.failures, "warning")}` else ""
	const suffix = if hint ~= nil then ` {hint}` else ""

	return `{done}{warnings}.{suffix}`
end

return successNotice
