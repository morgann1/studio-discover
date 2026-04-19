--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local React = require(StudioDiscover.Packages.React)

local Context = React.createContext(false)

local function useCompact(): boolean
	return React.useContext(Context)
end

return table.freeze({
	Provider = Context.Provider,
	useCompact = useCompact,
})
