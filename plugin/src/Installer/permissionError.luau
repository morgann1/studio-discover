--!strict

local MESSAGE = "Discover needs script injection permission to modify packages. "
	.. "Retry the action — Studio should now prompt you to allow it. "
	.. "If the permission was previously denied, grant it from Plugin → Manage Plugins → Discover."

local function isPermissionError(err: any): boolean
	if typeof(err) ~= "string" then
		return false
	end
	return string.find(err, "denied script injection permission", 1, true) ~= nil
end

local function describe(err: any): string
	if isPermissionError(err) then
		return MESSAGE
	end
	return tostring(err)
end

return table.freeze({
	isPermissionError = isPermissionError,
	describe = describe,
	MESSAGE = MESSAGE,
})
