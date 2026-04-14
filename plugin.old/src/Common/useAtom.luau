local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Charm = require(Packages.Charm)
local React = require(Packages.React)

local function useAtom<T>(selector: Charm.Selector<T>): T
	local value, setValue = React.useState(selector)

	React.useEffect(function()
		setValue(function(prev)
			local current = selector()
			if current ~= prev then
				return current
			end
			return prev
		end)

		return Charm.subscribe(selector, function(next_)
			setValue(next_)
		end)
	end, { selector } :: { any })

	return value
end

return useAtom
