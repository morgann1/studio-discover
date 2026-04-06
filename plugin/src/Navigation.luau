local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)

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
}

local BASE_SCREEN: Screen = {
	id = "base",
	name = "Home",
	options = {},
}

local Context = React.createContext(nil :: NavigationContext?)

local function generateId(): string
	local chars = "abcdefghijklmnopqrstuvwxyz0123456789"
	local result = {}
	for _ = 1, 12 do
		local i = math.random(1, #chars)
		table.insert(result, string.sub(chars, i, i))
	end
	return table.concat(result)
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

	local value = React.useMemo(function()
		return {
			push = push,
			pop = pop,
			replace = replace,
			screen = screen,
		}
	end, { push, pop, replace, screen })

	return React.createElement(Context.Provider, {
		value = value,
	}, props.children)
end

local function useNavigation(): NavigationContext
	local ctx = React.useContext(Context)
	assert(ctx, "useNavigation must be used within a NavigationProvider")
	return ctx
end

return {
	NavigationProvider = NavigationProvider,
	useNavigation = useNavigation,
}
