local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Charm = require(Packages.Charm)

export type Screen = {
	id: string,
	name: string,
	options: { [string]: any },
}

local BASE_SCREEN: Screen = {
	id = "base",
	name = "Home",
	options = {},
}

local stack = Charm.atom({} :: { Screen })

local activeScreen = Charm.computed(function(): Screen
	local current = stack()
	if #current > 0 then
		return current[#current]
	end
	return BASE_SCREEN
end)

local nextId = 0
local function generateId(): string
	nextId += 1
	return `screen-{nextId}`
end

local function push(name: string, options: { [string]: any }?)
	stack(function(prev)
		local updated = table.clone(prev)
		table.insert(updated, {
			id = generateId(),
			name = name,
			options = options or {},
		})
		return updated
	end)
end

local function pop()
	stack(function(prev)
		if #prev == 0 then
			return prev
		end
		local updated = table.clone(prev)
		table.remove(updated)
		return updated
	end)
end

local function replace(name: string, options: { [string]: any }?)
	Charm.batch(function()
		pop()
		push(name, options)
	end)
end

local function reset()
	stack({})
end

return {
	stack = stack,
	activeScreen = activeScreen,
	BASE_SCREEN = BASE_SCREEN,
	push = push,
	pop = pop,
	replace = replace,
	reset = reset,
}
