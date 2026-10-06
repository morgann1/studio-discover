--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const createPluginSettingsStore = require(StudioDiscover.Source.Plugin.createPluginSettingsStore)
const useAtom = require(StudioDiscover.Source.Common.useAtom)

type SidebarState = {
	read collapsed: boolean,
}

const DEFAULTS: SidebarState = {
	collapsed = false,
}

--[[
	Whether the user hid the sidebar. It only matters while the widget is wide enough
		to show one.

	It's layout state rather than a preference, so it's saved under its own key, out
		of reach of the Settings screen and its reset. A missing or corrupt saved value
		shows the sidebar.
]]
const store = createPluginSettingsStore("DiscoverSidebar", DEFAULTS, {
	collapsed = function(value: unknown)
		return typeof(value) == "boolean"
	end,
})

const function useIsCollapsed(): boolean
	return useAtom(function()
		return store.getStorage().collapsed
	end)
end

const function toggleCollapsed()
	store.setStorage(function(previous)
		return { collapsed = not previous.collapsed }
	end)
end

const SidebarStore = table.freeze({
	useIsCollapsed = useIsCollapsed,
	toggleCollapsed = toggleCollapsed,
})

return SidebarStore
