--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const Charm = require(StudioDiscover.Packages.Charm)

const useAtom = require(StudioDiscover.Source.Common.useAtom)

-- Whether the user hid the sidebar. It only matters while the widget is wide enough to show one.
const collapsedAtom = Charm.atom(false)

const function useIsCollapsed(): boolean
	return useAtom(function()
		return collapsedAtom()
	end)
end

const function toggleCollapsed()
	collapsedAtom(not collapsedAtom())
end

const SidebarStore = table.freeze({
	useIsCollapsed = useIsCollapsed,
	toggleCollapsed = toggleCollapsed,
})

return SidebarStore
