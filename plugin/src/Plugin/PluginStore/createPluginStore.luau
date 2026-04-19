--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Charm = require(StudioDiscover.Packages.Charm)

export type PluginStore = {
	getPlugin: () -> Plugin?,
	setPlugin: (Plugin?) -> (),
}

-- `plugin` is only defined in top-level plugin scripts; it has to be passed by
-- reference into this store once the bootstrap captures it, so ModuleScripts
-- lower in the tree can reach it via `PluginStore.get().getPlugin()`.
local function createPluginStore(): PluginStore
	local pluginAtom = Charm.atom(nil :: Plugin?)

	return {
		getPlugin = function(): Plugin?
			return pluginAtom()
		end,
		setPlugin = function(value: Plugin?)
			pluginAtom(value)
		end,
	}
end

return createPluginStore
