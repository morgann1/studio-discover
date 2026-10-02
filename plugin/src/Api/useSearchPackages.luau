--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const React = require(StudioDiscover.Packages.React)

const coreTypes = require(StudioDiscover.Libraries.Core.types)
const searchRegistryAsync = require(script.Parent.searchRegistryAsync)

const DEBOUNCE_SECONDS = 0.25
const MIN_QUERY_LENGTH = 2

export type SearchState = {
	read loading: boolean,
	read data: { coreTypes.PackageBrief }?,
	read error: string?,
}

const IDLE: SearchState = { loading = false }
const LOADING: SearchState = { loading = true }

--[[
	Searches each of `registries` for `query`, debounced, and lists the results in
		registry order. A package on two registries is listed once for each. An error is
		reported only when every registry failed. A query under two characters stays
		idle.
]]
const function useSearchPackages(query: string, registries: { coreTypes.Registry }): SearchState
	const state, setState = React.useState(IDLE)
	const registriesKey = table.concat(registries, ",")

	React.useEffect(function()
		local cancelled = false

		if #query < MIN_QUERY_LENGTH then
			setState(IDLE)
		elseif #registries == 0 then
			setState({ loading = false, data = {} })
		else
			setState(LOADING)

			task.delay(DEBOUNCE_SECONDS, function()
				const results: { [number]: { coreTypes.PackageBrief }? } = {}
				const errors: { string } = {}
				local remaining = #registries

				const function finish()
					remaining -= 1
					if remaining > 0 or cancelled then
						return
					end

					if #errors == #registries then
						setState({ loading = false, error = errors[1] })
						return
					end

					const merged: { coreTypes.PackageBrief } = {}
					for index = 1, #registries do
						const briefs = results[index] or {}
						table.move(briefs, 1, #briefs, #merged + 1, merged)
					end

					setState({ loading = false, data = merged })
				end

				for index, registry in registries do
					task.spawn(function()
						if cancelled then
							return
						end

						const briefs, err = searchRegistryAsync(registry, query)
						results[index] = briefs
						if briefs == nil then
							table.insert(errors, err or "Search failed")
						end

						finish()
					end)
				end
			end)
		end

		return function()
			cancelled = true
		end
	end, { query, registriesKey })

	return state
end

return useSearchPackages
