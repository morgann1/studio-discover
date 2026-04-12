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
	replace: (name: string, options: { [string]: any }?) -> (),
	screen: Screen,
	depth: number,
}

local BASE_SCREEN: Screen = {
	id = "base",
	name = "Home",
	options = {},
}

local Context = React.createContext(nil :: NavigationContext?)

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

local function NavigationProvider(props: { children: any })
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

	local replace = React.useCallback(function(name: string, options: { [string]: any }?)
		setStack(function(prev)
			local new = table.clone(prev)
			if #new > 0 then
				table.remove(new)
			end
			table.insert(new, {
				id = generateId(),
				name = name,
				options = options or {},
			})
			return new
		end)
	end, {})

	local screen = getScreen(stack)
	local depth = #stack + 1

	local value: NavigationContext = React.useMemo(function()
		local v: NavigationContext = {
			push = push,
			pop = pop,
			replace = replace,
			screen = screen,
			depth = depth,
		}
		return v
	end, { push, pop, replace, screen, depth } :: { any })

	return e(Context.Provider, {
		value = value,
	}, props.children)
end

local function useNavigation(): NavigationContext
	local navigationContext = React.useContext(Context)
	assert(navigationContext, "useNavigation must be used within a NavigationProvider")
	return navigationContext
end

return {
	NavigationProvider = NavigationProvider,
	useNavigation = useNavigation,
}
