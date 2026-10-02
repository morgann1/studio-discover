--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const React = require(StudioDiscover.Packages.React)

-- Whether the sidebar is compact, which screens use to pick a one-column layout.
const Context = React.createContext(false)

const function useCompact(): boolean
	return React.useContext(Context)
end

const CompactContext = table.freeze({
	Provider = Context.Provider,
	useCompact = useCompact,
})

return CompactContext
