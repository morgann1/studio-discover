--!strict

local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local HttpService = game:GetService("HttpService")

local React = require(Packages.React)

local e = React.createElement

export type Screen = {
	id: string,
	name: string,
	options: { [string]: any }?,
}

export type NavigationContext = {
	push: (name: string, options: { [string]: any }?) -> (),
	pop: () -> (),
	screen: Screen,
}

local BASE_SCREEN: Screen = {
	id = "base",
	name = "Home",
	options = {},
}

local DEFAULT_CONTEXT: NavigationContext = {
	push = function(_name, _options) end,
	pop = function() end,
	screen = BASE_SCREEN,
}

local Context = React.createContext<<NavigationContext>>(DEFAULT_CONTEXT)

local function generateId(): string
	return HttpService:GenerateGUID(false)
end

local function getScreen(stack: { Screen }): Screen
	if #stack > 0 then
		return stack[#stack]
	else
		return BASE_SCREEN
	end
end

local function NavigationProvider(props: { children: React.Node }): React.ReactNode
	local stack, setStack = React.useState({} :: { Screen })

	local push = React.useCallback(function(name: string, options: { [string]: any }?)
		setStack(function(prev)
			local new = table.clone(prev)
			table.insert(new, {
				id = generateId(),
				name = name,
				options = options or {},
			})
			return new
		end)
	end, {})

	local pop = React.useCallback(function()
		setStack(function(prev)
			if #prev == 0 then
				return prev
			end
			local new = table.clone(prev)
			table.remove(new)
			return new
		end)
	end, {})

	local screen = getScreen(stack)

	local value = React.useMemo(function(): NavigationContext
		return {
			push = push,
			pop = pop,
			screen = screen,
		}
	end, { push, pop, screen } :: { any })

	return e(Context.Provider, {
		value = value,
	}, props.children)
end

local function useNavigation(): NavigationContext
	return React.useContext(Context)
end

return {
	NavigationProvider = NavigationProvider,
	useNavigation = useNavigation,
}
