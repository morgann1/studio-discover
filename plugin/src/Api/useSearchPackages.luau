--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local React = require(StudioDiscover.Packages.React)

local searchPackagesAsync = require(StudioDiscover.Source.Api.searchPackagesAsync)
local searchPesdeAsync = require(StudioDiscover.Source.Api.searchPesdeAsync)
local types = require(StudioDiscover.Source.Api.types)

local DEBOUNCE_SECONDS = 0.25
local MIN_QUERY_LENGTH = 2

export type SearchState = {
	loading: boolean,
	data: { types.PackageBrief }?,
	error: string?,
}

local EMPTY: SearchState = table.freeze({
	loading = false,
	data = nil,
	error = nil,
})

local function briefsFromWally(wallyResults: { types.WallyPackageBrief }): { types.PackageBrief }
	local briefs: { types.PackageBrief } = {}
	for _, pkg in wallyResults do
		table.insert(briefs, {
			registry = "wally" :: "wally",
			scope = pkg.scope,
			name = pkg.name,
			description = pkg.description,
			latestVersion = pkg.versions[1],
		})
	end
	return briefs
end

-- Merged so exact `scope/name` matches across registries sit adjacent and a
-- Wally result wins the tie (surfaced first) since Wally has broader coverage
-- today.
local function sortBriefs(briefs: { types.PackageBrief })
	table.sort(briefs, function(a, b)
		local aKey = `{a.scope}/{a.name}`
		local bKey = `{b.scope}/{b.name}`
		if aKey == bKey then
			return a.registry == "wally"
		end
		return aKey < bKey
	end)
end

-- Runs the Wally and pesde search calls in parallel; each yields inside its
-- own task so the slower registry can't hold the faster one hostage.
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

			local wallyResults: { types.WallyPackageBrief }? = nil
			local wallyErr: string? = nil
			local pesdeResults: { types.PackageBrief }? = nil
			local pesdeErr: string? = nil
			local remaining = 2

			local function done()
				remaining -= 1
				if remaining > 0 or cancelled then
					return
				end

				local merged: { types.PackageBrief } = {}
				if wallyResults ~= nil then
					for _, brief in briefsFromWally(wallyResults) do
						table.insert(merged, brief)
					end
				end
				if pesdeResults ~= nil then
					for _, brief in pesdeResults do
						table.insert(merged, brief)
					end
				end
				sortBriefs(merged)

				local finalError: string? = nil
				if wallyResults == nil and pesdeResults == nil then
					finalError = wallyErr or pesdeErr or "Search failed"
				end

				setState({
					loading = false,
					data = if finalError ~= nil then nil else merged,
					error = finalError,
				})
			end

			task.spawn(function()
				wallyResults, wallyErr = searchPackagesAsync(query)
				done()
			end)

			task.spawn(function()
				pesdeResults, pesdeErr = searchPesdeAsync(query)
				done()
			end)
		end)

		return function()
			cancelled = true
		end
	end, { query })

	return state
end

return useSearchPackages
