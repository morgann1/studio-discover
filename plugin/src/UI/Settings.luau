local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local Charm = require(Packages.Charm)

export type NamingConvention = "As-Is" | "PascalCase" | "camelCase" | "snake_case" | "kebab-case"

local DEFAULTS: { [string]: any } = {
	checkForUpdates = true,
	dismissedUpdateVersion = "",
	namingConvention = "As-Is" :: NamingConvention,
	reduceMotion = false,
	verboseLogging = false,
	nameOverrides = {} :: { [string]: string },
}

local atoms: { [string]: Charm.Atom<any> } = {}
for name, default in DEFAULTS do
	atoms[name] = Charm.atom(default)
end

local pluginRef: Plugin? = script:FindFirstAncestorWhichIsA("Plugin")
local loaded = false

local function storageKey(name: string): string
	return `Discover_{name}`
end

local function load()
	if loaded or not pluginRef then
		return
	end
	loaded = true
	for name, _ in DEFAULTS do
		local saved = pluginRef:GetSetting(storageKey(name))
		if saved ~= nil then
			atoms[name](saved)
		end
	end
end

local function get(name: string): any
	load()
	local atom = atoms[name]
	if atom == nil then
		error(`Invalid setting name: {name}`, 2)
	end
	return atom()
end

local function set(name: string, value: any)
	load()
	local atom = atoms[name]
	if atom == nil then
		error(`Invalid setting name: {name}`, 2)
	end
	atom(value)
	if pluginRef then
		task.spawn(pluginRef.SetSetting, pluginRef, storageKey(name), value)
	end
end

load()

return {
	defaults = DEFAULTS,
	atoms = atoms,
	get = get,
	set = set,
}
