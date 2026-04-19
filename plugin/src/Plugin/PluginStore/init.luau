--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local Charm = require(StudioDiscover.Packages.Charm)

local createPluginStore = require(script.createPluginStore)

return table.freeze({
	get = Charm.computed(createPluginStore),
})
