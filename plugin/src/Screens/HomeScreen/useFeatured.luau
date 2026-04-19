--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local React = require(StudioDiscover.Packages.React)

local getPackageMetadataAsync = require(StudioDiscover.Source.Api.Wally.getMetadataAsync)

type FeaturedRef = {
	scope: string,
	name: string,
}

local FEATURED: { FeaturedRef } = table.freeze({
	{ scope = "jsdotlua", name = "react" },
	{ scope = "sleitnick", name = "signal" },
	{ scope = "evaera", name = "promise" },
	{ scope = "osyrisrblx", name = "t" },
	{ scope = "sleitnick", name = "knit" },
	{ scope = "howmanysmall", name = "janitor" },
	{ scope = "sleitnick", name = "trove" },
	{ scope = "littensy", name = "charm" },
}) :: { FeaturedRef }

export type FeaturedPackage = {
	scope: string,
	name: string,
	description: string?,
	latestVersion: string?,
}

export type FeaturedState = {
	loading: boolean,
	packages: { FeaturedPackage },
}

local EMPTY: FeaturedState = { loading = true, packages = {} }

-- Hardcoded curated list; metadata is pulled lazily so the home page picks
-- up version bumps without needing a rebuild. `getPackageMetadataAsync`
-- caches per session so reopens are free.
local function useFeatured(): FeaturedState
	local state: FeaturedState, setState = React.useState(EMPTY)

	React.useEffect(function(): (() -> ())?
		local cancelled = false
		setState({ loading = true, packages = {} })

		task.spawn(function()
			local packages: { FeaturedPackage } = {}
			for _, entry in FEATURED do
				if cancelled then
					return
				end
				local metadata = getPackageMetadataAsync(entry.scope, entry.name)
				if metadata == nil or metadata.versions == nil or #metadata.versions == 0 then
					continue
				end
				local latest = metadata.versions[1]
				table.insert(packages, {
					scope = entry.scope,
					name = entry.name,
					description = latest.package.description,
					latestVersion = latest.package.version,
				})
			end
			if cancelled then
				return
			end
			setState({ loading = false, packages = packages })
		end)

		return function()
			cancelled = true
		end
	end, {})

	return state
end

return useFeatured
