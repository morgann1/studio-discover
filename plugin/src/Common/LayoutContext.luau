--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const React = require(StudioDiscover.Packages.React)

--[[
	`isWide` is whether the widget is above Foundation's Small breakpoint, which decides
		how many columns a screen shows. `isDocked` is whether the sidebar is gone,
		because the widget is narrow or the user hid it, so the header carries the
		location menu and screens show their own search row.
]]
export type Layout = {
	read isWide: boolean,
	read isDocked: boolean,
}

const Context = React.createContext<<Layout>>({
	isWide = true,
	isDocked = false,
})

const function useLayout(): Layout
	return React.useContext(Context)
end

const LayoutContext = table.freeze({
	Provider = Context.Provider,
	useLayout = useLayout,
})

return LayoutContext
