local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Charm = require(Packages.Charm)
local React = require(Packages.React)

local useEffect = React.useEffect
local useState = React.useState

local function useAtom<T>(selector: Charm.Selector<T>): T
	local value, setValue = useState(function()
		return selector()
	end)

	useEffect(function()
		setValue(selector())
		return Charm.subscribe(selector, function(newValue)
			setValue(newValue)
		end)
	end, { selector } :: { any })

	return value
end

return useAtom
