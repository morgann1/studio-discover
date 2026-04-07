local Discover = script:FindFirstAncestor("Discover")
local Packages = Discover.Packages

local React = require(Packages.React)

export type SearchState = {
	text: string,
	results: { any },
	isLoading: boolean,
	hasSearched: boolean,
	error: string?,
}

export type SearchContext = {
	state: SearchState,
	setState: (patch: { [string]: any }) -> (),
	reset: () -> (),
}

local DEFAULT_STATE: SearchState = {
	text = "",
	results = {},
	isLoading = false,
	hasSearched = false,
	error = nil,
}

local Context = React.createContext(nil :: SearchContext?)

local function SearchProvider(props: { children: any })
	local state, setInternalState = React.useState(DEFAULT_STATE)

	local setState = React.useCallback(function(patch: { [string]: any })
		setInternalState(function(prev: SearchState): SearchState
			local next_: any = table.clone(prev)
			for k, v in patch do
				next_[k] = v
			end
			return next_
		end)
	end, {})

	local reset = React.useCallback(function()
		setInternalState(DEFAULT_STATE)
	end, {})

	local value: SearchContext = React.useMemo(function()
		local v: SearchContext = {
			state = state,
			setState = setState,
			reset = reset,
		}
		return v
	end, { state, setState, reset })

	return React.createElement(Context.Provider, { value = value }, props.children)
end

local function useSearch(): SearchContext
	local ctx = React.useContext(Context)
	assert(ctx, "useSearch must be used within a SearchProvider")
	return ctx
end

return {
	SearchProvider = SearchProvider,
	useSearch = useSearch,
}
