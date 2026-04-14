local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Charm = require(Packages.Charm)

export type Screen = {
	id: string,
	name: string,
	options: { [string]: any },
}

local SECTIONS = { "Home", "Installed", "Updates", "Settings", "About" }

local nextId = 0
local function generateId(): string
	nextId += 1
	return `screen-{nextId}`
end

local function makeScreen(name: string, options: { [string]: any }?): Screen
	return {
		id = generateId(),
		name = name,
		options = options or {},
	}
end

-- Stack is a two-level navigation model: entry 1 is always the current
-- section (picked by the sidebar); entries 2+ are drill-down screens
-- within that section (e.g. Home → Package, Settings → Overrides).
local stack = Charm.atom({ makeScreen("Home") } :: { Screen })

local activeScreen = Charm.computed(function(): Screen
	local current = stack()
	return current[#current]
end)

local activeSection = Charm.computed(function(): string
	local current = stack()
	return current[1].name
end)

local function push(name: string, options: { [string]: any }?)
	stack(function(prev)
		local updated = table.clone(prev)
		table.insert(updated, makeScreen(name, options))
		return updated
	end)
end

local function pop()
	stack(function(prev)
		if #prev <= 1 then
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

-- Replace the whole stack with a fresh section root. Used by the sidebar
-- so switching sections always lands you at the section's root, not a
-- drill-down left over from last time.
local function resetTo(sectionName: string)
	stack({ makeScreen(sectionName) })
end

return {
	SECTIONS = SECTIONS,
	stack = stack,
	activeScreen = activeScreen,
	activeSection = activeSection,
	push = push,
	pop = pop,
	replace = replace,
	resetTo = resetTo,
}
