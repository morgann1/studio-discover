--!strict

const StudioDiscover = script:FindFirstAncestor("StudioDiscover")

const React = require(StudioDiscover.Packages.React)

const SettingsStore = require(StudioDiscover.Source.SettingsStore)
const coreTypes = require(StudioDiscover.Libraries.Core.types)
const searchPesdeAsync = require(StudioDiscover.Libraries.PesdeRegistry.Api.searchAsync)
const searchWallyAsync = require(StudioDiscover.Libraries.WallyRegistry.Api.searchAsync)

const DEBOUNCE_SECONDS = 0.25
const MIN_QUERY_LENGTH = 2

export type SearchState = {
	read loading: boolean,
	read data: { coreTypes.PackageBrief }?,
	read error: string?,
}

const IDLE: SearchState = { loading = false }
const LOADING: SearchState = { loading = true }

-- Merges results for the same scope/name from both registries into one brief, sorted by scope/name.
const function mergeBriefs(...: { coreTypes.PackageBrief }): { coreTypes.PackageBrief }
	const byKey: { [string]: coreTypes.PackageBrief } = {}
	const keys: { string } = {}

	for _, briefs in { ... } do
		for _, brief in briefs do
			const key = `{brief.scope}/{brief.name}`
			const existing = byKey[key]

			if existing == nil then
				byKey[key] = brief
				table.insert(keys, key)
				continue
			end

			const registries = table.clone(existing.registries)
			for _, registry in brief.registries do
				if table.find(registries, registry) == nil then
					table.insert(registries, registry)
				end
			end

			byKey[key] = {
				registries = registries,
				scope = existing.scope,
				name = existing.name,
				description = existing.description or brief.description,
				latestVersion = existing.latestVersion or brief.latestVersion,
			}
		end
	end

	table.sort(keys)

	const merged: { coreTypes.PackageBrief } = {}
	for _, key in keys do
		table.insert(merged, byKey[key])
	end

	return merged
end

--[[
	Searches every enabled registry for `query`, debounced, and merges the results.
		An error is reported only when every enabled registry failed.
]]
const function useSearchPackages(query: string): SearchState
	const registries = SettingsStore.useSettings().registries
	const wallyEnabled = registries.wally
	const pesdeEnabled = registries.pesde
	const state, setState = React.useState(IDLE)

	React.useEffect(function()
		local cancelled = false

		if #query < MIN_QUERY_LENGTH then
			setState(IDLE)
		else
			task.delay(DEBOUNCE_SECONDS, function()
				if cancelled then
					return
				end

				if not wallyEnabled and not pesdeEnabled then
					setState({ loading = false, data = {} })
					return
				end

				setState(LOADING)

				local wallyResults: { coreTypes.PackageBrief }? = nil
				local wallyError: string? = nil
				local pesdeResults: { coreTypes.PackageBrief }? = nil
				local pesdeError: string? = nil
				local remaining = (if wallyEnabled then 1 else 0) + (if pesdeEnabled then 1 else 0)

				const function finish()
					remaining -= 1
					if remaining > 0 or cancelled then
						return
					end

					const wallyFailed = wallyEnabled and wallyResults == nil
					const pesdeFailed = pesdeEnabled and pesdeResults == nil
					if (wallyFailed or not wallyEnabled) and (pesdeFailed or not pesdeEnabled) then
						setState({ loading = false, error = wallyError or pesdeError or "Search failed" })
						return
					end

					setState({ loading = false, data = mergeBriefs(wallyResults or {}, pesdeResults or {}) })
				end

				if wallyEnabled then
					task.spawn(function()
						const results, err = searchWallyAsync(query)
						wallyResults = results
						wallyError = err
						finish()
					end)
				end

				if pesdeEnabled then
					task.spawn(function()
						pesdeResults, pesdeError = searchPesdeAsync(query)
						finish()
					end)
				end
			end)
		end

		return function()
			cancelled = true
		end
	end, { query, wallyEnabled, pesdeEnabled } :: { unknown })

	return state
end

return useSearchPackages
