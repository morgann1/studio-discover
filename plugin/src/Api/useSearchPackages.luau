--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local React = require(StudioDiscover.Packages.React)

local searchPackagesAsync = require(StudioDiscover.Source.Api.Wally.searchAsync)
local searchPesdeAsync = require(StudioDiscover.Source.Api.Pesde.searchAsync)
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
			registries = { "wally" :: types.Registry },
			scope = pkg.scope,
			name = pkg.name,
			description = pkg.description,
			latestVersion = pkg.versions[1],
		})
	end
	return briefs
end

local function hasRegistry(registries: { types.Registry }, target: types.Registry): boolean
	for _, r in registries do
		if r == target then
			return true
		end
	end
	return false
end

local function mergeBriefs(left: { types.PackageBrief }, right: { types.PackageBrief }): { types.PackageBrief }
	local byKey: { [string]: types.PackageBrief } = {}
	local order: { string } = {}

	local function absorb(brief: types.PackageBrief)
		local key = `{brief.scope}/{brief.name}`
		local existing = byKey[key]
		if existing == nil then
			byKey[key] = {
				registries = table.clone(brief.registries),
				scope = brief.scope,
				name = brief.name,
				description = brief.description,
				latestVersion = brief.latestVersion,
			}
			table.insert(order, key)
			return
		end
		for _, registry: types.Registry in brief.registries do
			if not hasRegistry(existing.registries, registry) then
				table.insert(existing.registries, registry)
			end
		end
		if existing.description == nil then
			existing.description = brief.description
		end
		if existing.latestVersion == nil then
			existing.latestVersion = brief.latestVersion
		end
	end

	for _, brief in left do
		absorb(brief)
	end
	for _, brief in right do
		absorb(brief)
	end

	local out: { types.PackageBrief } = {}
	for _, key in order do
		table.insert(out, byKey[key])
	end
	return out
end

local function sortBriefs(briefs: { types.PackageBrief })
	table.sort(briefs, function(a, b)
		return `{a.scope}/{a.name}` < `{b.scope}/{b.name}`
	end)
end

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

				local wallyBriefs = if wallyResults ~= nil then briefsFromWally(wallyResults) else {}
				local pesdeBriefs = pesdeResults or {}
				local merged = mergeBriefs(wallyBriefs, pesdeBriefs)
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
