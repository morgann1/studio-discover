--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const buildTree = require(StudioDiscover.Core.buildTree)
const setScriptSourceAsync = require(StudioDiscover.Core.setScriptSourceAsync)

--[[
	Writes the sources `buildTree` left pending, stopping at the first that fails.
		Returns that failure as "path: error", or nil when every write succeeded.
]]
const function writePendingSourcesAsync(pending: { buildTree.PendingSource }): string?
	for _, item in pending do
		const ok, err = setScriptSourceAsync(item.script, item.content)
		if not ok then
			return `{item.path}: {err}`
		end
	end

	return nil
end

return writePendingSourcesAsync
