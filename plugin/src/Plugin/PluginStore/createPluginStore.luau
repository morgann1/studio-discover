--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Charm = require(StudioDiscover.Packages.Charm)

export type PluginStore = {
	getPlugin: () -> Plugin?,
	setPlugin: (Plugin?) -> (),
}

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
