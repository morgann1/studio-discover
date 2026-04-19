--!strict

local createScreenId = require(script.Parent.createScreenId)
local screensAtom = require(script.Parent.screensAtom)
local types = require(script.Parent.types)

local function resetScreen(name: string, options: { [string]: any }?)
	local screen: types.Screen = {
		id = createScreenId(),
		name = name,
		options = options or {},
	}
	screensAtom({ screen })
end

return resetScreen
