--!strict

const HttpService = game:GetService("HttpService")

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const asTable = require(StudioDiscover.Libraries.Core.asTable)

--[[
	Reads a package's `default.project.json` and returns its root `$path`, the part
		of the archive that installs, without a leading `./`. Returns nil when the
		project doesn't parse or its root has no path below the package, so the whole
		archive installs.
]]
const function readProjectSourcePath(projectJson: string): string?
	const ok, decoded = pcall(HttpService.JSONDecode, HttpService, projectJson)
	const project = if ok then asTable(decoded) else nil
	const tree = if project ~= nil then asTable(project.tree) else nil
	const path = if tree ~= nil then tree["$path"] else nil

	if typeof(path) == "string" and path ~= "" and path ~= "." then
		return (string.gsub(path, "^%./", ""))
	end

	return nil
end

return readProjectSourcePath
