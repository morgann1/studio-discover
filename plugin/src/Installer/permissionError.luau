--!strict

const MESSAGE = "Discover needs script injection permission to modify packages. "
	.. "Retry the action, and Studio should prompt you to allow it. "
	.. "If the permission was previously denied, grant it from Plugin → Manage Plugins → Discover."

--[[
	Describes an error thrown while writing to the place. Studio's script injection
		denial becomes instructions for granting it, and anything else is passed through.
]]
const function permissionError(err: unknown): string
	if typeof(err) == "string" and string.find(err, "denied script injection permission", 1, true) ~= nil then
		return MESSAGE
	end

	return tostring(err)
end

return permissionError
