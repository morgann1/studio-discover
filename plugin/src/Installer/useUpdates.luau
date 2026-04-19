--!strict

local StudioDiscover = script:FindFirstAncestor("StudioDiscover")

local React = require(StudioDiscover.Packages.React)

local getPackageMetadataAsync = require(StudioDiscover.Source.Api.getPackageMetadataAsync)

local compareSemver = require(StudioDiscover.Source.Util.compareSemver)
local parseSemver = require(StudioDiscover.Source.Util.parseSemver)

local useInstalledRoots = require(StudioDiscover.Source.Installer.useInstalledRoots)

type Realm = "shared" | "server"

export type UpdateInfo = {
	scope: string,
	name: string,
	realm: Realm,
	alias: string,
	installedVersion: string,
	latestVersion: string,
}

export type UpdatesState = {
	updates: { UpdateInfo },
	loading: boolean,
}

local EMPTY: UpdatesState = { updates = {}, loading = false }

-- Fetches are sequential so the 1-RPS Wally rate limiter isn't starved;
-- `getPackageMetadataAsync` caches, so repeat renders don't re-hit the API.
local function useUpdates(): UpdatesState
	local installedRoots = useInstalledRoots()
	local state: UpdatesState, setState = React.useState(EMPTY)

	React.useEffect(function(): (() -> ())?
		if #installedRoots == 0 then
			setState(EMPTY)
			return nil
		end

		local cancelled = false
		setState({ updates = {}, loading = true })

		task.spawn(function()
			local updates: { UpdateInfo } = {}
			for _, root in installedRoots do
				if cancelled then
					return
				end
				local metadata = getPackageMetadataAsync(root.scope, root.name)
				if metadata == nil or metadata.versions == nil or #metadata.versions == 0 then
					continue
				end
				local latest = metadata.versions[1].package.version
				local latestSv = parseSemver(latest)
				local installedSv = parseSemver(root.version)
				if latestSv == nil or installedSv == nil then
					continue
				end
				if compareSemver(latestSv, installedSv) > 0 then
					table.insert(updates, {
						scope = root.scope,
						name = root.name,
						realm = root.realm,
						alias = root.alias,
						installedVersion = root.version,
						latestVersion = latest,
					})
				end
			end
			if cancelled then
				return
			end
			setState({ updates = updates, loading = false })
		end)

		return function()
			cancelled = true
		end
	end, { installedRoots } :: { any })

	return state
end

return useUpdates
