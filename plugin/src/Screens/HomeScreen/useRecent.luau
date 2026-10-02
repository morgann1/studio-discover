--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const React = require(StudioDiscover.Packages.React)

const searchPesdeAsync = require(StudioDiscover.Libraries.PesdeRegistry.Api.searchAsync)
const types = require(StudioDiscover.Libraries.Core.types)

const LIMIT = 12

export type RecentState = {
	read loading: boolean,
	read packages: { types.PackageBrief },
	read error: string?,
}

const LOADING: RecentState = { loading = true, packages = {} }

-- Fetches the first page of pesde's listing once, on mount.
const function useRecent(): RecentState
	const state, setState = React.useState(LOADING)

	React.useEffect(function()
		local cancelled = false

		task.spawn(function()
			const results, err = searchPesdeAsync("")
			if cancelled then
				return
			end

			if results == nil then
				setState({ loading = false, packages = {}, error = err })
				return
			end

			setState({
				loading = false,
				packages = table.move(results, 1, math.min(#results, LIMIT), 1, {}),
			})
		end)

		return function()
			cancelled = true
		end
	end, {})

	return state
end

return useRecent
