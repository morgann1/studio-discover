--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local React = require(StudioDiscover.Packages.React)

local searchPackagesAsync = require(StudioDiscover.Source.Api.searchPackagesAsync)
local types = require(StudioDiscover.Source.Api.types)

local DEBOUNCE_SECONDS = 0.25
local MIN_QUERY_LENGTH = 2

export type SearchState = {
	loading: boolean,
	data: { types.WallyPackageBrief }?,
	error: string?,
}

local EMPTY: SearchState = table.freeze({
	loading = false,
	data = nil,
	error = nil,
})

-- Debounces query changes and discards superseded responses via a cancelled
-- flag. The in-flight request runs to completion either way so its result
-- lands in the URL cache, making rapid re-queries of the same string hit the
-- cache instead of the network.
local function useSearchPackages(query: string): SearchState
	local state: SearchState, setState = React.useState(EMPTY)

	React.useEffect(function(): (() -> ())?
		if #query < MIN_QUERY_LENGTH then
			setState(EMPTY)
			return nil
		end

		local cancelled = false

		task.delay(DEBOUNCE_SECONDS, function()
			if cancelled then
				return
			end

			setState({ loading = true, data = nil, error = nil })

			local data, err = searchPackagesAsync(query)

			if cancelled then
				return
			end

			setState({
				loading = false,
				data = data,
				error = err,
			})
		end)

		return function()
			cancelled = true
		end
	end, { query })

	return state
end

return useSearchPackages
