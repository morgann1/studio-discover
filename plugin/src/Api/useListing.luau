--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const React = require(StudioDiscover.Packages.React)

const coreTypes = require(StudioDiscover.Libraries.Core.types)
const featuredWallyPackages = require(script.Parent.featuredWallyPackages)
const searchPesdeAsync = require(StudioDiscover.Libraries.PesdeRegistry.Api.searchAsync)
const useSearchPackages = require(script.Parent.useSearchPackages)

const FEATURED: useSearchPackages.SearchState = { loading = false, data = featuredWallyPackages }
const LOADING: useSearchPackages.SearchState = { loading = true }

--[[
	What a source lists before the user searches it: popular packages for Wally, and
		pesde's own listing of its latest packages.
]]
const function useListing(registry: coreTypes.Registry): useSearchPackages.SearchState
	const state, setState = React.useState(if registry == "wally" then FEATURED else LOADING)

	React.useEffect(function()
		local cancelled = false

		if registry == "wally" then
			setState(FEATURED)
		else
			setState(LOADING)

			task.spawn(function()
				const results, err = searchPesdeAsync("")
				if not cancelled then
					setState({ loading = false, data = results, error = err })
				end
			end)
		end

		return function()
			cancelled = true
		end
	end, { registry })

	return state
end

return useListing
